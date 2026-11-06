// Trunk gate: a PreToolUse hook that makes Claude ask before it commits to, merges into, or
// pushes to a protected branch, and blocks force-pushes and deletes of one outright.
//
// Protected: the remote's default branch (origin/HEAD), main, master, support/*, vN/main and
// vN/dev. It backs the git-workflow rule "always ask before touching main or a support
// branch" with something Claude can't forget.
//
// Reads the hook input as JSON on stdin and prints a decision as JSON on stdout. Prints
// nothing when the command is fine. Any error also prints nothing: a broken gate must never
// stop someone working, so it fails open.
//
// Turn it off for a project by setting UMBRACO_DEVKIT_TRUNK_GATE=off (for example in the
// "env" block of .claude/settings.json).
//
// Node only, no dependencies, so it runs the same on Windows, macOS and Linux.

import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { isAbsolute, resolve } from "node:path";
import { pathToFileURL } from "node:url";

const SEPARATORS = new Set(["&&", "||", ";", "|", "&", "\n"]);
const COMMITTING = new Set(["commit", "merge", "cherry-pick", "revert", "am"]);
const ESCAPES_OUT = ["--abort", "--quit", "--skip"];
// Global git options that take a value as the next word.
const GIT_OPTS_WITH_VALUE = new Set(["-C", "-c", "--git-dir", "--work-tree", "--namespace", "--exec-path"]);

// Inside double quotes, Bash treats a backslash as an escape only before these. Anywhere else in
// double quotes it's literal, so "C:\Users\me" keeps its backslashes.
const DOUBLE_QUOTE_ESCAPABLE = new Set(["$", "`", '"', "\\", "\n"]);

/**
 * Splits a command line into words, keeping quoted text together, with separators as their own
 * words. PowerShell escapes with a backtick, not a backslash, so `cd C:\repo` keeps its path there.
 */
export function tokenize(line, { powershell = false } = {}) {
  const escape = powershell ? "`" : "\\";
  const words = [];
  let word = "";
  let inWord = false;
  let quote = null;
  let depth = 0; // $( ... ) nesting, so a heredoc commit message stays one word
  const push = () => { if (inWord) words.push(word); word = ""; inWord = false; };
  for (let i = 0; i < line.length; i++) {
    const c = line[i];
    if (quote) {
      if (c === escape && quote === '"' && i + 1 < line.length && (powershell || DOUBLE_QUOTE_ESCAPABLE.has(line[i + 1]))) {
        word += line[++i];
        continue;
      }
      if (c === "$" && line[i + 1] === "(") { depth++; word += "$("; i++; continue; }
      if (c === ")" && depth > 0) { depth--; word += c; continue; }
      if (c === quote && depth === 0) { quote = null; continue; }
      word += c;
      continue;
    }
    if (c === "'" || c === '"') { quote = c; inWord = true; continue; }
    if (c === escape && i + 1 < line.length) { word += line[++i]; inWord = true; continue; }
    if (c === "$" && line[i + 1] === "(") { depth++; word += "$("; i++; inWord = true; continue; }
    if (c === ")" && depth > 0) { depth--; word += c; continue; }
    if (depth > 0) { word += c; inWord = true; continue; }
    if (c === " " || c === "\t" || c === "\r") { push(); continue; }
    if (c === "\n" || c === ";") { push(); words.push(c); continue; }
    if (c === "&" || c === "|") {
      push();
      if (line[i + 1] === c) { words.push(c + c); i++; } else { words.push(c); }
      continue;
    }
    word += c;
    inWord = true;
  }
  push();
  return words;
}

function segments(words) {
  const out = [[]];
  for (const w of words) {
    if (SEPARATORS.has(w)) out.push([]);
    else out[out.length - 1].push(w);
  }
  return out.filter((s) => s.length > 0);
}

function git(dir, args) {
  try {
    return execFileSync("git", ["-C", dir, ...args], { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] }).trim();
  } catch {
    return null;
  }
}

function currentBranch(dir) {
  return git(dir, ["symbolic-ref", "--quiet", "--short", "HEAD"]) || null;
}

function isProtected(dir, branch) {
  if (!branch) return false;
  if (branch === "main" || branch === "master") return true;
  if (/^support\//.test(branch)) return true;
  if (/^v\d+\/(main|dev)$/.test(branch)) return true;
  const head = git(dir, ["symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD"]);
  return !!head && head.replace(/^origin\//, "") === branch;
}

function expandHome(p) {
  return p === "~" || p.startsWith("~/") ? homedir() + p.slice(1) : p;
}

/** Works out what one `git push` would do to protected branches. */
function checkPush(dir, args) {
  let force = false;
  let del = false;
  let everything = false;
  const positional = [];
  for (let i = 0; i < args.length; i++) {
    const a = args[i];
    if (a === "--") { positional.push(...args.slice(i + 1)); break; }
    if (a === "-f" || a === "--force" || a.startsWith("--force-with-lease") || a === "--force-if-includes") { force = true; continue; }
    if (a === "-d" || a === "--delete") { del = true; continue; }
    if (a === "--all" || a === "--mirror" || a === "--branches") { everything = true; if (a === "--mirror") force = true; continue; }
    if (a === "-o" || a === "--push-option" || a === "--repo" || a === "--receive-pack" || a === "--exec") { i++; continue; }
    if (a.startsWith("-")) {
      // Short flags can be bundled: -uf means -u -f.
      if (/^-[a-zA-Z]+$/.test(a) && a.includes("f")) force = true;
      continue;
    }
    positional.push(a);
  }

  const here = currentBranch(dir);
  const targets = [];
  if (everything) {
    targets.push({ branch: "(every branch)", force, del: false, protected: true });
  } else if (positional.length <= 1) {
    // No refspec: git pushes the current branch to its upstream, which has the same name
    // under the default push.default.
    targets.push({ branch: here, force, del, protected: isProtected(dir, here) });
  } else {
    for (const spec of positional.slice(1)) {
      let s = spec;
      let f = force;
      if (s.startsWith("+")) { f = true; s = s.slice(1); }
      const colon = s.indexOf(":");
      let dst = colon >= 0 ? s.slice(colon + 1) : s;
      const isDelete = del || (colon === 0);
      if (dst === "HEAD" || dst === "@") dst = here;
      dst = (dst || "").replace(/^refs\/heads\//, "");
      targets.push({ branch: dst, force: f, del: isDelete, protected: isProtected(dir, dst) });
    }
  }

  let decision = null;
  for (const t of targets.filter((t) => t.protected)) {
    if (t.force || t.del) {
      return {
        decision: "deny",
        reason: `${t.del ? "Deleting" : "Force-pushing to"} ${t.branch}, a protected branch, is blocked by the umbraco-devkit trunk gate. ` +
          "It rewrites or removes history other people build on. If it is really needed, ask the user to run it themselves.",
      };
    }
    decision = {
      decision: "ask",
      reason: `This pushes to ${t.branch}, a protected branch. The umbraco-devkit trunk gate asks a person to confirm first.`,
    };
  }
  return decision;
}

function checkCommit(dir, sub, args) {
  if (args.some((a) => ESCAPES_OUT.includes(a))) return null;
  if (sub === "merge" && args.includes("--ff-only")) return null; // only moves the branch to commits that already exist
  const branch = currentBranch(dir);
  if (!isProtected(dir, branch)) return null;
  const verb = sub === "commit" ? "commits" : `runs git ${sub}, which commits,`;
  return {
    decision: "ask",
    reason: `This ${verb} straight onto ${branch}, a protected branch. The umbraco-devkit trunk gate asks a person to confirm first.`,
  };
}

/** Returns { decision, reason } for a shell command, or null when it doesn't touch a protected branch. */
export function decide(command, cwd, tool = "Bash") {
  let dir = cwd;
  let result = null;
  for (const seg of segments(tokenize(command, { powershell: tool === "PowerShell" }))) {
    let i = 0;
    while (i < seg.length && /^[A-Za-z_][A-Za-z0-9_]*=/.test(seg[i])) i++; // FOO=bar git ...
    const cmd = seg[i];
    if (cmd === undefined) continue;
    if (cmd === "cd" || cmd === "Set-Location" || cmd === "pushd") {
      const target = seg[i + 1];
      if (target && target !== "-") dir = resolve(dir, expandHome(target));
      continue;
    }
    if (!(cmd === "git" || cmd === "git.exe" || /[\\/]git(\.exe)?$/.test(cmd))) continue;

    let gitDir = dir;
    let j = i + 1;
    while (j < seg.length && seg[j].startsWith("-")) {
      const opt = seg[j];
      if (opt === "-C" && j + 1 < seg.length) {
        const p = expandHome(seg[j + 1]);
        gitDir = isAbsolute(p) ? p : resolve(gitDir, p);
      }
      j += GIT_OPTS_WITH_VALUE.has(opt) ? 2 : 1;
    }
    const sub = seg[j];
    const rest = seg.slice(j + 1);
    let r = null;
    if (COMMITTING.has(sub)) r = checkCommit(gitDir, sub, rest);
    else if (sub === "push") r = checkPush(gitDir, rest);
    if (!r) continue;
    if (r.decision === "deny") return r;
    result = result || r;
  }
  return result;
}

function main() {
  if ((process.env.UMBRACO_DEVKIT_TRUNK_GATE || "").toLowerCase() === "off") return;
  const input = JSON.parse(readFileSync(0, "utf8"));
  const command = input?.tool_input?.command;
  if (typeof command !== "string" || !/\bgit\b/.test(command)) return;
  const r = decide(command, input.cwd || process.cwd(), input.tool_name);
  if (!r) return;
  process.stdout.write(JSON.stringify({
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: r.decision,
      permissionDecisionReason: r.reason + " (Turn this check off with UMBRACO_DEVKIT_TRUNK_GATE=off.)",
    },
  }));
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  try { main(); } catch { /* fail open */ }
}
