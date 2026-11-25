#!/usr/bin/env node
// Embargo: keeps an unreleased security fix off every remote except its private fork.
//
// A fix for an undisclosed vulnerability must not reach a public remote before the advisory is
// published. An embargo is keyed by the advisory's GHSA id and marks the branches that hold the
// fix. The only remote allowed to receive them is the advisory's private fork, which GitHub
// names after the repo and the id: github.com/<owner>/<repo>-ghsa-xxxx-xxxx-xxxx, for a repo
// this checkout has as a remote. The allowed remote is worked out, never stored, so it can't be
// loosened. An embargo with an id that isn't a GHSA id (an internal ticket, when there is no
// private fork) allows no remote at all.
//
// Nothing else may receive the fix: not under its own branch name, not merged or cherry-picked
// into another branch, and not rebased onto a new base (matched by patch id, so a reworded
// commit still counts).
//
// The embargo lives in the repo's local git config, so it is never committed, it covers every
// worktree of the checkout, and it survives a /clear:
//
//   [devkit-embargo "GHSA-xxxx-xxxx-xxxx"]
//       branch = v18/hotfix/access-check
//       branch = v17/hotfix/access-check
//
// Two guards read it. The embargo-gate hook stops Claude Code. A git pre-push hook, which `add`
// installs, stops everyone else: a push from a terminal, an editor, or a GUI client. Both fail
// closed: if an embargo exists and the check can't run, the push is blocked.
//
// Only a person lifts an embargo, once the fix is approved to ship:
//
//   git config --remove-section devkit-embargo.<id>
//
// Usage:
//   node embargo.mjs add <GHSA id> --branch <name> [--branch <name>...]
//   node embargo.mjs status
//   node embargo.mjs pre-push <remote> <url>     (run by git, reads the refs on stdin)
//
// Node only, no dependencies: `add` copies this file into the repo's hooks folder, where it runs
// on its own. It runs the same on Windows, macOS and Linux.

import { spawnSync } from "node:child_process";
import { chmodSync, copyFileSync, existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { join, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

export const SECTION = "devkit-embargo";
const MARK = "# umbraco-devkit embargo guard";
const COPY_NAME = "umbraco-devkit-embargo.mjs";
const ZERO_SHA = /^0+$/;

function gitRaw(dir, args, input) {
  const r = spawnSync("git", ["-C", dir, ...args], {
    encoding: "utf8",
    input,
    maxBuffer: 256 * 1024 * 1024,
    stdio: [input === undefined ? "ignore" : "pipe", "pipe", "pipe"],
  });
  if (r.error) throw r.error;
  return { status: r.status, out: (r.stdout || "").trim(), err: (r.stderr || "").trim() };
}

function git(dir, args, input) {
  const r = gitRaw(dir, args, input);
  if (r.status !== 0) throw new Error(`git ${args[0]} failed: ${r.err || `exit ${r.status}`}`);
  return r.out;
}

function lines(text) {
  return text ? text.split(/\r?\n/).filter(Boolean) : [];
}

/** Reduces a remote URL to host/owner/repo, so https, ssh and scp-style forms compare equal. */
export function normalizeUrl(url) {
  let s = String(url).trim().toLowerCase();
  s = s.replace(/^[a-z][a-z0-9+.-]*:\/\//, ""); // scheme
  s = s.replace(/^[^@/]+@/, ""); // user, or a token, before the host
  s = s.replace(/^([^/:]+):(?!\d+\/)/, "$1/"); // scp-like host:owner/repo
  s = s.replace(/\/+$/, "").replace(/\.git$/, "").replace(/\/+$/, "");
  return s;
}

/** The embargoes recorded in this repo. Throws if git can't be read; [] when there are none. */
export function readEmbargoes(dir) {
  const r = gitRaw(dir, ["config", "--get-regexp", `^${SECTION}\\.`]);
  if (r.status === 1 && !r.err) return [];
  if (r.status !== 0) throw new Error(r.err || `git config exit ${r.status}`);
  const byId = new Map();
  for (const line of lines(r.out)) {
    const space = line.indexOf(" ");
    const key = space < 0 ? line : line.slice(0, space);
    const value = space < 0 ? "" : line.slice(space + 1).trim();
    const rest = key.slice(SECTION.length + 1);
    const dot = rest.lastIndexOf(".");
    if (dot <= 0) continue;
    const id = rest.slice(0, dot);
    const name = rest.slice(dot + 1).toLowerCase();
    if (!byId.has(id)) byId.set(id, { id, branches: [] });
    if (name === "branch" && value) byId.get(id).branches.push(value.replace(/^refs\/heads\//, ""));
  }
  return [...byId.values()];
}

const GHSA_ID = /^ghsa(-[a-z0-9]{4}){3}$/i;

/**
 * The private fork URLs an embargo allows: each remote's repo with -ghsa-<id> on the end. A
 * remote that already ends that way (a checkout cloned from the fork) is the fork itself.
 */
export function allowedUrls(embargo, all) {
  if (!GHSA_ID.test(embargo.id)) return [];
  const suffix = `-${embargo.id.toLowerCase()}`;
  return [...new Set(all.flatMap((r) => r.urls).map((u) => (u.endsWith(suffix) ? u : u + suffix)))];
}

/** Every configured remote with its push URLs. */
export function remotes(dir) {
  return lines(git(dir, ["remote"])).map((name) => ({
    name,
    urls: lines(gitRaw(dir, ["remote", "get-url", "--push", "--all", name]).out).map(normalizeUrl),
  }));
}

/** Remotes this embargo doesn't allow. Their remote-tracking branches count as public. */
function publicRemotes(all, allowed) {
  return all.filter((r) => !r.urls.some((u) => allowed.includes(u))).map((r) => r.name);
}

function notPublic(pub) {
  return pub.length ? ["--not", ...pub.map((name) => `--remotes=${name}`)] : [];
}

function refExists(dir, ref) {
  return gitRaw(dir, ["rev-parse", "--verify", "--quiet", `${ref}^{commit}`]).status === 0;
}

function patchIds(dir, revArgs) {
  const patches = git(dir, ["log", "-p", "--no-merges", "--no-color", "--no-ext-diff", "--no-textconv", ...revArgs]);
  if (!patches) return [];
  return lines(git(dir, ["patch-id", "--stable"], patches + "\n")).map((l) => l.split(" ")[0]);
}

/** The commits an embargo protects: on its branches, and not already on a public remote. */
function protectedCommits(dir, embargo, pub) {
  const shas = new Set();
  const ids = new Set();
  for (const b of embargo.branches) {
    const ref = `refs/heads/${b}`;
    if (!refExists(dir, ref)) continue;
    const range = [ref, ...notPublic(pub)];
    for (const s of lines(git(dir, ["rev-list", ...range]))) shas.add(s);
    for (const p of patchIds(dir, range)) ids.add(p);
  }
  return { shas, ids };
}

function shortRef(ref) {
  return (ref || "").replace(/^refs\/heads\//, "");
}

function blocked(embargo, allowed, what, url) {
  return {
    id: embargo.id,
    reason:
      `${what} holds unreleased security fix commits under embargo ${embargo.id}, and ${url} is not its private fork` +
      `${allowed.length ? ` (${allowed.join(" or ")})` : " (it has none, so nothing may be pushed)"}. ` +
      "Only a person can lift the embargo, once the fix is approved to ship.",
  };
}

/**
 * Checks a push. `updates` is what git sends a pre-push hook: [{ localRef, sha, remoteRef }].
 * Returns null when the push is fine, or { id, reason } when an embargo blocks it. Throws when it
 * can't tell, which callers treat as blocked.
 */
export function checkPush(dir, { url, updates }) {
  const embargoes = readEmbargoes(dir);
  if (!embargoes.length) return null;
  const target = normalizeUrl(url);
  const all = remotes(dir);
  for (const e of embargoes) {
    const allowed = allowedUrls(e, all);
    if (allowed.includes(target)) continue;
    const pub = publicRemotes(all, allowed);
    let known = null;
    for (const u of updates) {
      if (!u.sha || ZERO_SHA.test(u.sha)) continue; // a delete sends no commits
      const names = [shortRef(u.localRef), shortRef(u.remoteRef)];
      const named = names.find((n) => e.branches.includes(n));
      if (named) return blocked(e, allowed, `Branch ${named}`, url);
      known = known || protectedCommits(dir, e, pub);
      if (!known.shas.size) continue;
      const range = [u.sha, ...notPublic(pub)];
      const what = `${names[0] || u.sha.slice(0, 12)}`;
      if (lines(git(dir, ["rev-list", ...range])).some((s) => known.shas.has(s))) return blocked(e, allowed, what, url);
      if (patchIds(dir, range).some((p) => known.ids.has(p))) return blocked(e, allowed, `${what} (a copy of the fix)`, url);
    }
  }
  return null;
}

/** The hooks folder git runs, or null with a reason when installing there isn't safe. */
function hooksDir(dir) {
  const custom = gitRaw(dir, ["config", "--get", "core.hooksPath"]).out;
  if (custom) return { dir: null, why: `core.hooksPath is set to ${custom}, so hooks are managed by another tool` };
  return { dir: resolve(dir, git(dir, ["rev-parse", "--git-path", "hooks"])), why: null };
}

/** Installs, or refreshes, the git pre-push guard. Returns { installed, why }. */
export function installPrePush(dir) {
  const { dir: hooks, why } = hooksDir(dir);
  if (!hooks) return { installed: false, why };
  mkdirSync(hooks, { recursive: true });
  const hook = join(hooks, "pre-push");
  if (existsSync(hook) && !readFileSync(hook, "utf8").includes(MARK)) {
    return { installed: false, why: `${hook} already exists and isn't this guard` };
  }
  copyFileSync(fileURLToPath(import.meta.url), join(hooks, COPY_NAME));
  writeFileSync(
    hook,
    "#!/bin/sh\n" +
      `${MARK}\n` +
      "# Blocks pushing an unreleased security fix to any remote except its private fork.\n" +
      `# It does nothing once no embargo is left (git config --get-regexp ^${SECTION}\\.).\n` +
      `exec node "$(dirname "$0")/${COPY_NAME}" pre-push "$@"\n`,
  );
  try { chmodSync(hook, 0o755); } catch { /* Windows: git runs it through sh anyway */ }
  return { installed: true, why: null };
}

function prePushInstalled(dir) {
  const { dir: hooks } = hooksDir(dir);
  if (!hooks) return false;
  const hook = join(hooks, "pre-push");
  return existsSync(hook) && readFileSync(hook, "utf8").includes(MARK);
}

function add(dir, argv) {
  const id = argv[0];
  if (!id || id.startsWith("-") || !/^[A-Za-z0-9._-]+$/.test(id)) {
    throw new Error("key the embargo by the advisory's GHSA id, or an internal ticket id when there is no advisory");
  }
  const branches = [];
  for (let i = 1; i < argv.length; i++) {
    if (argv[i] === "--branch" && argv[i + 1]) branches.push(argv[++i].replace(/^refs\/heads\//, ""));
    else throw new Error(`unknown argument ${argv[i]}`);
  }
  if (!branches.length) throw new Error("name at least one --branch");
  // Same key in any case, so GHSA-ABCD and ghsa-abcd are one embargo.
  const existing = readEmbargoes(dir).find((e) => e.id.toLowerCase() === id.toLowerCase());
  const key = existing ? existing.id : id;
  for (const b of branches) {
    if (!existing || !existing.branches.includes(b)) git(dir, ["config", "--add", `${SECTION}.${key}.branch`, b]);
  }
  const guard = installPrePush(dir);
  process.stdout.write(`Embargo ${key} recorded.\n`);
  if (!guard.installed) {
    process.stdout.write(
      `The git pre-push guard is NOT installed: ${guard.why}. Pushes from outside Claude Code are not checked. ` +
        `Add this line to that pre-push hook to check them:\n  node "<path to>/embargo.mjs" pre-push "$1" "$2"\n`,
    );
  }
  status(dir);
}

function status(dir) {
  const embargoes = readEmbargoes(dir);
  if (!embargoes.length) {
    process.stdout.write("No embargo in this repo.\n");
    return;
  }
  const all = remotes(dir);
  for (const e of embargoes) {
    process.stdout.write(`\nEmbargo ${e.id}\n`);
    const allowed = allowedUrls(e, all);
    process.stdout.write(`  Private fork: ${allowed.length ? allowed.join(" or ") : "none (nothing may be pushed)"}\n`);
    const pub = all.filter((r) => !r.urls.some((u) => allowed.includes(u)));
    for (const b of e.branches) {
      const here = refExists(dir, `refs/heads/${b}`) ? "" : " (no local branch yet)";
      const leaked = pub.filter((r) => refExists(dir, `refs/remotes/${r.name}/${b}`)).map((r) => r.name);
      const warn = leaked.length ? `  WARNING: already on public remote ${leaked.join(", ")}` : "";
      process.stdout.write(`  Branch ${b}${here}${warn}\n`);
    }
    process.stdout.write(`  Lift (a person, once approved): git config --remove-section ${SECTION}.${e.id}\n`);
  }
  process.stdout.write(`\nGit pre-push guard: ${prePushInstalled(dir) ? "installed" : "NOT installed"}\n`);
}

function prePush(dir, remote, url) {
  const updates = lines(readFileSync(0, "utf8")).map((l) => {
    const [localRef, sha, remoteRef] = l.split(" ");
    return { localRef, sha, remoteRef };
  });
  let r;
  try {
    r = checkPush(dir, { url: url || remote, updates });
  } catch (err) {
    r = { reason: `The umbraco-devkit embargo check couldn't run (${err.message}), so the push is blocked to be safe.` };
  }
  if (!r) return 0;
  process.stderr.write(`\nPush blocked by the umbraco-devkit embargo guard.\n${r.reason}\n\n`);
  return 1;
}

function main(argv) {
  const [cmd, ...rest] = argv;
  const dir = process.cwd();
  if (cmd === "pre-push") return prePush(dir, rest[0], rest[1]);
  try {
    if (cmd === "add") add(dir, rest);
    else if (cmd === "status") status(dir);
    else {
      process.stderr.write("Usage: embargo.mjs add <GHSA id> --branch <name> [--branch <name>...] | status\n");
      return 2;
    }
    return 0;
  } catch (err) {
    process.stderr.write(`embargo: ${err.message}\n`);
    return 1;
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  process.exitCode = main(process.argv.slice(2));
}
