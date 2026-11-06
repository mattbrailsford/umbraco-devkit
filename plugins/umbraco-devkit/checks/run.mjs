// Pre-review checks: cheap, mechanical checks on a task's uncommitted changes, run before the
// reviewer so a one-line slip doesn't cost a full review round.
//
// Each check is one file in ./builtin/ exporting a default object:
//
//   {
//     name: "plan-links",            // shown with each finding; used to turn a check off
//     files: (path) => boolean,      // optional: which changed files checkFile sees
//     checkFile({ path, added, text, bytes }) => [{ line?, message }],   // optional
//     checkRepo({ changed, untracked }) => [{ path?, line?, message }],  // optional
//   }
//
// `added` is the file's added lines as [{ line, text }]; `text` is the whole file, or null when
// it isn't valid UTF-8; `bytes` is the raw file. `changed` and `untracked` are repo-relative
// paths with forward slashes.
//
// A project adds its own checks as .mjs files in .claude/checks/ (same shape), and turns a
// check off by name in .claude/checks/config.json: { "disabled": ["plan-links"] }.
//
// Usage: node run.mjs [--base <ref>] [--cwd <dir>] [--json]
//   --base  compare against this ref instead of HEAD (a re-review round's snapshot)
// Prints one finding per line; exit 1 if any, 0 if none, 2 if the checks couldn't run.
//
// Node only, no dependencies, so it runs the same on Windows, macOS and Linux.

import { execFileSync } from "node:child_process";
import { existsSync, readdirSync, readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const HERE = dirname(fileURLToPath(import.meta.url));

function git(cwd, args) {
  return execFileSync("git", args, { cwd, encoding: "utf8", maxBuffer: 64 * 1024 * 1024 });
}

function lines(out) {
  return out.split(/\r?\n/).filter(Boolean);
}

/** Added lines per file from a zero-context diff, as Map<path, [{ line, text }]>. */
export function parseDiff(diff) {
  const files = new Map();
  let current = null;
  let next = 0;
  for (const raw of diff.split(/\r?\n/)) {
    if (raw.startsWith("+++ ")) {
      const target = raw.slice(4);
      current = target === "/dev/null" ? null : target.replace(/^b\//, "");
      if (current && !files.has(current)) files.set(current, []);
      continue;
    }
    const hunk = /^@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@/.exec(raw);
    if (hunk) {
      next = Number(hunk[1]);
      continue;
    }
    if (!current) continue;
    if (raw.startsWith("+")) files.get(current).push({ line: next++, text: raw.slice(1) });
  }
  return files;
}

async function loadChecks(folder) {
  if (!existsSync(folder)) return [];
  const checks = [];
  for (const file of readdirSync(folder).filter((f) => f.endsWith(".mjs")).sort()) {
    const mod = await import(pathToFileURL(join(folder, file)).href);
    if (mod.default?.name) checks.push(mod.default);
  }
  return checks;
}

function readConfig(root) {
  const file = join(root, ".claude", "checks", "config.json");
  if (!existsSync(file)) return {};
  return JSON.parse(readFileSync(file, "utf8"));
}

/** Runs every check on the working tree's changes against `base`. Returns the findings. */
export async function runChecks({ cwd = process.cwd(), base = "HEAD" } = {}) {
  const root = git(cwd, ["rev-parse", "--show-toplevel"]).trim();
  const config = readConfig(root);
  const disabled = new Set(config.disabled ?? []);
  const checks = [
    ...(await loadChecks(join(HERE, "builtin"))),
    ...(await loadChecks(join(root, ".claude", "checks"))),
  ].filter((c) => !disabled.has(c.name));

  const added = parseDiff(git(root, ["diff", "--no-color", "--no-ext-diff", "-U0", base, "--"]));
  const untracked = lines(git(root, ["ls-files", "--others", "--exclude-standard"]));
  for (const path of untracked) {
    const text = readFileSync(join(root, path), "utf8");
    added.set(path, text.split(/\r?\n/).map((t, i) => ({ line: i + 1, text: t })));
  }
  const changed = [...added.keys()];

  const findings = [];
  const decoder = new TextDecoder("utf-8", { fatal: true });
  for (const check of checks) {
    if (check.checkRepo) {
      for (const f of check.checkRepo({ changed, untracked })) findings.push({ check: check.name, ...f });
    }
    if (!check.checkFile) continue;
    for (const path of changed) {
      if (check.files && !check.files(path)) continue;
      const full = join(root, path);
      if (!existsSync(full)) continue;
      const bytes = readFileSync(full);
      let text = null;
      try {
        text = decoder.decode(bytes);
      } catch {
        // Not UTF-8: checks that need text skip it; the encoding check reports it.
      }
      for (const f of check.checkFile({ path, added: added.get(path), text, bytes })) {
        findings.push({ check: check.name, path, ...f });
      }
    }
  }
  return findings;
}

export function format(f) {
  const where = f.path ? `${f.path}${f.line ? `:${f.line}` : ""}: ` : "";
  return `${where}${f.message} [${f.check}]`;
}

async function main(argv) {
  const opts = { cwd: process.cwd(), base: "HEAD" };
  let json = false;
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === "--base") opts.base = argv[++i];
    else if (argv[i] === "--cwd") opts.cwd = resolve(argv[++i]);
    else if (argv[i] === "--json") json = true;
  }
  let findings;
  try {
    findings = await runChecks(opts);
  } catch (err) {
    console.error(`Pre-review checks couldn't run: ${err.message}`);
    return 2;
  }
  if (json) console.log(JSON.stringify(findings, null, 2));
  else for (const f of findings) console.log(format(f));
  return findings.length ? 1 : 0;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  process.exitCode = await main(process.argv.slice(2));
}
