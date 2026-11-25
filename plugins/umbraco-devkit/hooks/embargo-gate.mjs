// Embargo gate: a PreToolUse hook that stops Claude from publishing an unreleased security fix.
//
// When a repo has an embargo (see embargo.mjs), it blocks, never asks:
// - `git push` of an embargoed branch, or of anything holding its commits or a copy of them, to
//   a remote the embargo doesn't allow;
// - `gh pr create` from such a branch against a repo the embargo doesn't allow;
// - lifting or loosening the embargo: `git embargo lift` or `embargo.mjs lift`, writing its git
//   config other than adding a branch or a ticket, changing the `git embargo` shortcut, and
//   editing the repo's git config or hooks with the file tools;
// - an advisory or ticket id in a commit, tag or merge message, a branch name, pull request or
//   issue text, or the messages of pushed commits. Words that point at a security fix there are
//   asked about instead, since plain fixes use them too.
//
// It blocks instead of asking because one quick "yes" would make the fix public before the
// advisory. A person lifts the embargo themselves when the fix is approved to ship.
//
// Repos without an embargo are never affected. If an embargo exists and the check can't run, it
// blocks (fails closed). It has no off switch: remove the embargo instead.
//
// Node only, no dependencies, so it runs the same on Windows, macOS and Linux.

import { spawnSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { dirname, resolve, sep } from "node:path";
import { pathToFileURL } from "node:url";
import { SECTION, checkPush, checkWording, normalizeUrl, pushedText, readEmbargoes, remotes, wordingReason } from "./embargo.mjs";
import { commandCalls, gitCall, isGit } from "./trunk-gate.mjs";

const PUSH_OPTS_WITH_VALUE = new Set(["-o", "--push-option", "--receive-pack", "--exec", "--repo"]);
const CONFIG_READS = new Set(["--get", "--get-all", "--get-regexp", "--get-urlmatch", "--list", "-l", "get", "list"]);

function git(dir, args) {
  const r = spawnSync("git", ["-C", dir, ...args], { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] });
  return r.status === 0 ? r.stdout.trim() : null;
}

function embargoesIn(dir) {
  try {
    return readEmbargoes(dir);
  } catch {
    return []; // not a repo: nothing to protect here
  }
}

function deny(reason) {
  return { decision: "deny", reason };
}

function resolveCommit(dir, rev) {
  return git(dir, ["rev-parse", "--verify", "--quiet", `${rev}^{commit}`]);
}

/** The remote a bare `git push` uses, the way git picks it. */
function defaultRemote(dir, branch) {
  return (
    (branch && git(dir, ["config", "--get", `branch.${branch}.pushRemote`])) ||
    git(dir, ["config", "--get", "remote.pushDefault"]) ||
    (branch && git(dir, ["config", "--get", `branch.${branch}.remote`])) ||
    "origin"
  );
}

function urlsFor(dir, remote) {
  const named = remotes(dir).find((r) => r.name === remote);
  return named ? named.urls : [normalizeUrl(remote)];
}

/** Works out the remote URLs and ref updates one `git push` would send. */
function pushPlan(dir, args) {
  const positional = [];
  let every = false;
  let tags = false;
  let remoteOpt = null;
  for (let i = 0; i < args.length; i++) {
    const a = args[i];
    if (a === "--") { positional.push(...args.slice(i + 1)); break; }
    if (a === "-d" || a === "--delete") return null; // deletes send no commits
    if (a === "--all" || a === "--branches" || a === "--mirror") { every = true; if (a === "--mirror") tags = true; continue; }
    if (a === "--tags") { tags = true; continue; }
    if (a.startsWith("--repo=")) { remoteOpt = a.slice(7); continue; }
    if (PUSH_OPTS_WITH_VALUE.has(a)) { if (a === "--repo") remoteOpt = args[i + 1]; i++; continue; }
    if (a.startsWith("-")) continue;
    positional.push(a);
  }
  const branch = git(dir, ["symbolic-ref", "--quiet", "--short", "HEAD"]);
  const remote = positional[0] || remoteOpt || defaultRemote(dir, branch);
  const updates = [];
  const addRef = (ref) => {
    const sha = resolveCommit(dir, ref);
    if (!sha) throw new Error(`can't tell what ${ref} is`);
    updates.push({ localRef: ref, sha, remoteRef: ref });
  };
  if (every || tags) {
    const patterns = [...(every ? ["refs/heads"] : []), ...(tags ? ["refs/tags"] : [])];
    for (const ref of (git(dir, ["for-each-ref", "--format=%(refname)", ...patterns]) || "").split("\n").filter(Boolean)) addRef(ref);
  }
  const specs = positional.slice(1);
  if (!specs.length && !every && !tags) {
    if (!branch) throw new Error("HEAD is not on a branch");
    addRef(`refs/heads/${branch}`);
  }
  for (let spec of specs) {
    if (spec.startsWith("+")) spec = spec.slice(1);
    const colon = spec.indexOf(":");
    const src = colon >= 0 ? spec.slice(0, colon) : spec;
    const dst = colon >= 0 ? spec.slice(colon + 1) : spec;
    if (!src) continue; // ":branch" deletes
    const sha = resolveCommit(dir, src);
    if (!sha) throw new Error(`can't tell what ${src} is`);
    const localRef = src === "HEAD" || src === "@" ? (branch ? `refs/heads/${branch}` : src) : src;
    updates.push({ localRef, sha, remoteRef: dst === "HEAD" || dst === "@" ? localRef : dst });
  }
  return { remote, urls: urlsFor(dir, remote), updates };
}

function checkGitPush(dir, args) {
  if (!embargoesIn(dir).length) return null;
  try {
    const plan = pushPlan(dir, args);
    if (!plan) return null;
    for (const url of plan.urls) {
      const r = checkPush(dir, { url, updates: plan.updates });
      if (r) return deny(r.reason);
    }
    return wording(dir, pushedText(dir, plan.updates));
  } catch (err) {
    return deny(`This repo has a security embargo and the umbraco-devkit embargo gate couldn't check this push (${err.message}), so it's blocked to be safe.`);
  }
}

function checkGitConfig(dir, args) {
  if (args.some((a) => /^alias\.embargo$/i.test(a)) && !args.some((a) => CONFIG_READS.has(a)) && embargoesIn(dir).length) {
    return deny("This changes the git embargo shortcut, which could make it lift the embargo. Only a person lifts an embargo.");
  }
  if (!args.some((a) => a.toLowerCase().includes(SECTION))) {
    // `git config --edit` can change anything, the embargo included.
    if ((args.includes("-e") || args.includes("--edit") || args[0] === "edit") && embargoesIn(dir).length) {
      return deny("This repo has a security embargo, and editing its git config by hand could lift it. Only a person lifts an embargo.");
    }
    return null;
  }
  if (args.some((a) => CONFIG_READS.has(a))) return null;
  // Adding a branch tightens an embargo; anything else (unset, remove, rename) loosens it.
  const key = args.find((a) => a.toLowerCase().startsWith(`${SECTION}.`)) || "";
  if (args.includes("--add") && /\.(branch|ticket)$/i.test(key)) return null;
  return deny(
    "This changes a security embargo. Only a person lifts or loosens one, once the fix is approved to ship. " +
      "To record a new embargo or add a branch, use the plugin's embargo.mjs add.",
  );
}

function ghValue(args, short, long) {
  for (let i = 0; i < args.length; i++) {
    if (args[i] === short || args[i] === long) return args[i + 1];
    if (args[i].startsWith(`${long}=`)) return args[i].slice(long.length + 1);
  }
  return null;
}

/** The repo `gh pr create` targets when no --repo is given: gh's resolved default, else upstream, else origin. */
function ghDefaultRemote(dir) {
  const resolved = git(dir, ["config", "--get-regexp", "^remote\\..*\\.gh-resolved$"]);
  if (resolved) {
    const base = resolved.split("\n").find((l) => / base$/.test(l));
    if (base) return base.replace(/^remote\./, "").replace(/\.gh-resolved base$/, "");
  }
  const names = remotes(dir).map((r) => r.name);
  return names.includes("upstream") ? "upstream" : "origin";
}

function checkGhPrCreate(dir, args) {
  if (!embargoesIn(dir).length) return null;
  try {
    const repo = ghValue(args, "-R", "--repo");
    // gh takes [HOST/]OWNER/REPO or a URL.
    const ghRepo = (v) => (/^[^/:@]+\/[^/:@]+$/.test(v) ? `github.com/${v}` : v);
    const urls = repo ? [normalizeUrl(ghRepo(repo))] : urlsFor(dir, ghDefaultRemote(dir));
    let head = ghValue(args, "-H", "--head") || git(dir, ["symbolic-ref", "--quiet", "--short", "HEAD"]);
    if (!head) throw new Error("HEAD is not on a branch");
    head = head.includes(":") ? head.slice(head.indexOf(":") + 1) : head;
    const sha = resolveCommit(dir, `refs/heads/${head}`) || resolveCommit(dir, head);
    if (!sha) throw new Error(`can't tell what ${head} is`);
    for (const url of urls) {
      const r = checkPush(dir, { url, updates: [{ localRef: `refs/heads/${head}`, sha, remoteRef: `refs/heads/${head}` }] });
      if (r) return deny(`Opening this pull request would publish it. ${r.reason}`);
    }
    return null;
  } catch (err) {
    return deny(`This repo has a security embargo and the umbraco-devkit embargo gate couldn't check this pull request (${err.message}), so it's blocked to be safe.`);
  }
}

function wording(dir, text) {
  const r = checkWording(embargoesIn(dir), text);
  return r ? { decision: r.level === "block" ? "deny" : "ask", reason: wordingReason(r) } : null;
}

const FILE_OPTS = new Set(["-F", "--file", "--body-file"]);

function readText(dir, file) {
  return file && file !== "-" ? readFileSync(resolve(dir, file), "utf8") : "";
}

/** A git message: every -m / --message value (also in a cluster like -am) and any -F file. */
function messageText(dir, args) {
  const parts = [];
  for (let i = 0; i < args.length; i++) {
    const a = args[i];
    if (a === "--") break;
    if (a === "--message" || a === "--file") parts.push(a === "--file" ? readText(dir, args[++i]) : args[++i] || "");
    else if (a.startsWith("--message=")) parts.push(a.slice(10));
    else if (a.startsWith("--file=")) parts.push(readText(dir, a.slice(7)));
    else if (/^-[A-Za-z]+$/.test(a) && /[mF]$/.test(a)) parts.push(a.endsWith("F") ? readText(dir, args[++i]) : args[++i] || "");
    else if (/^-m./.test(a)) parts.push(a.slice(2));
  }
  return parts.join("\n");
}

const BRANCH_LISTS = new Set(["-d", "-D", "--delete", "-l", "--list", "-r", "-a", "--all", "--show-current", "--contains", "--merged", "--no-merged", "-u", "--set-upstream-to", "--unset-upstream"]);

/** The text a git command would publish: messages, and the names of new branches and tags. */
function gitText(dir, sub, args) {
  if (sub === "commit" || sub === "merge") return messageText(dir, args);
  const value = (flags) => {
    const i = args.findIndex((a) => flags.includes(a));
    return i >= 0 ? args[i + 1] || "" : "";
  };
  if (sub === "checkout") return value(["-b", "-B", "--orphan"]);
  if (sub === "switch") return value(["-c", "-C", "--create", "--force-create", "--orphan"]);
  if (sub === "worktree") return args[0] === "add" ? value(["-b", "-B"]) : "";
  const positional = args.filter((a) => !a.startsWith("-"));
  if (sub === "branch") return args.some((a) => BRANCH_LISTS.has(a)) ? "" : positional.join("\n");
  if (sub === "tag") return args.some((a) => ["-d", "--delete", "-l", "--list", "-v", "--verify"].includes(a)) ? "" : `${positional[0] || ""}\n${messageText(dir, args)}`;
  return "";
}

/** The text a gh command would publish: every argument except the repo, plus any body file. */
function ghText(dir, args) {
  const parts = [];
  for (let i = 0; i < args.length; i++) {
    const a = args[i];
    if (a === "-R" || a === "--repo") { i++; continue; }
    if (a.startsWith("--repo=")) continue;
    if (FILE_OPTS.has(a)) { parts.push(readText(dir, args[++i])); continue; }
    if (a.startsWith("--body-file=")) { parts.push(readText(dir, a.slice(12))); continue; }
    parts.push(a);
  }
  return parts.join("\n");
}

const GIT_TEXT = new Set(["commit", "tag", "merge", "checkout", "switch", "branch", "worktree"]);
const GH_TEXT = { pr: new Set(["create", "edit", "comment", "review"]), issue: new Set(["create", "edit", "comment"]) };

function checkText(dir, getText) {
  if (!embargoesIn(dir).length) return null;
  try {
    return wording(dir, getText());
  } catch (err) {
    return deny(`This repo has a security embargo and the umbraco-devkit embargo gate couldn't check this text (${err.message}), so it's blocked to be safe.`);
  }
}

/** Returns { decision, reason } for a shell command, or null when no embargo is at stake. */
export function decideCommand(command, cwd, tool = "Bash") {
  for (const call of commandCalls(command, cwd, tool)) {
    let r = null;
    const words = [call.cmd, ...call.args];
    if (words.includes("lift") && words.some((w) => /embargo(\.mjs)?$/i.test(w))) {
      return deny("Only a person lifts an embargo, at their own terminal, once the fix is approved to ship. Tell the user it's ready to lift, and the command: git embargo lift");
    }
    if (isGit(call.cmd)) {
      const { dir, sub, rest } = gitCall(call);
      if (sub === "push") r = checkGitPush(dir, rest);
      else if (sub === "config") r = checkGitConfig(dir, rest);
      else if (GIT_TEXT.has(sub)) r = checkText(dir, () => gitText(dir, sub, rest));
    } else if (/(^|[\\/])gh(\.exe)?$/.test(call.cmd)) {
      const [noun, verb] = call.args;
      if (noun === "pr" && verb === "create") r = checkGhPrCreate(call.dir, call.args.slice(2));
      if (!r && GH_TEXT[noun] && GH_TEXT[noun].has(verb)) r = checkText(call.dir, () => ghText(call.dir, call.args.slice(2)));
    }
    if (r) return r;
  }
  return null;
}

/** Blocks file-tool edits to a repo's git config or hooks while it has an embargo. */
export function decideFileEdit(filePath, cwd) {
  if (typeof filePath !== "string") return null;
  const full = resolve(cwd, filePath);
  const parts = full.split(/[\\/]/);
  const at = parts.lastIndexOf(".git");
  if (at < 0) return null;
  const inside = parts.slice(at + 1);
  if (!(inside.includes("config") || inside.includes("hooks"))) return null;
  const repo = parts.slice(0, at).join(sep) || sep;
  if (!embargoesIn(repo).length && !embargoesIn(dirname(full)).length) return null;
  return deny("This repo has a security embargo, and editing its git config or hooks could lift it. Only a person lifts an embargo.");
}

function main() {
  const input = JSON.parse(readFileSync(0, "utf8"));
  const cwd = input.cwd || process.cwd();
  const ti = input.tool_input || {};
  let r = null;
  if (typeof ti.command === "string") {
    if (!/\b(git|gh)\b|embargo/.test(ti.command)) return;
    r = decideCommand(ti.command, cwd, input.tool_name);
  } else {
    r = decideFileEdit(ti.file_path || ti.notebook_path, cwd);
  }
  if (!r) return;
  process.stdout.write(JSON.stringify({
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: r.decision,
      permissionDecisionReason: r.reason,
    },
  }));
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  try { main(); } catch { /* bad input: nothing to decide */ }
}
