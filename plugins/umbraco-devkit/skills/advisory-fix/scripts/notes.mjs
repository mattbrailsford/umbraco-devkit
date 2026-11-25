#!/usr/bin/env node
// Advisory notes: reads and writes an advisory's private file inside the repo's git folder.
//
// The file lives at <git common dir>/devkit-advisories/<key>.md. There, no worktree tracks it,
// no push carries it, every worktree of the checkout sees it, and it survives a /clear. Claude
// Code's file tools won't write inside a git folder, so every change goes through this script.
//
// Usage (run from anywhere inside the repo):
//   node notes.mjs <key>                          create it from the template if missing, then print it
//   node notes.mjs <key> --path                   print only the file's path
//   node notes.mjs <key> --append <heading>       add stdin to the end of a "## <heading>" section
//   node notes.mjs <key> --section <heading>      replace a "## <heading>" section's body with stdin
//   node notes.mjs <key> --write                  replace the whole file with stdin
//
// A heading matches case-insensitively, by its first words ("log" finds "## Log"). A section
// that doesn't exist yet is added at the end. Every change keeps the previous version as
// <key>.md.bak, and is written to a temporary file first, so a failed write never leaves half a
// file.
//
// Node only, no dependencies, and it doesn't run git. It runs the same on Windows, macOS and Linux.

import { copyFileSync, existsSync, mkdirSync, readFileSync, renameSync, statSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const TEMPLATE = join(dirname(fileURLToPath(import.meta.url)), "..", "templates", "advisory.md");
const KEY = /^[A-Za-z0-9][A-Za-z0-9._-]*$/;

/**
 * The repo's shared git folder, found without running git: walk up to the nearest `.git`. In a
 * worktree that's a file pointing at the worktree's own folder, whose `commondir` points back
 * at the shared one.
 */
export function gitCommonDir(cwd) {
  for (let dir = resolve(cwd); ; dir = dirname(dir)) {
    const dotGit = join(dir, ".git");
    if (existsSync(dotGit)) {
      if (statSync(dotGit).isDirectory()) return dotGit;
      const m = /^gitdir:\s*(.+)$/m.exec(readFileSync(dotGit, "utf8"));
      if (!m) throw new Error(`${dotGit} doesn't say where the git folder is`);
      const own = resolve(dir, m[1].trim());
      const common = join(own, "commondir");
      return existsSync(common) ? resolve(own, readFileSync(common, "utf8").trim()) : own;
    }
    if (dirname(dir) === dir) throw new Error("not inside a git repo");
  }
}

export function notesPath(cwd, key) {
  if (!KEY.test(key)) throw new Error("the key is the GHSA id or the security ticket id: letters, digits, '.', '_' or '-'");
  return join(gitCommonDir(cwd), "devkit-advisories", `${key}.md`);
}

function save(file, text) {
  mkdirSync(dirname(file), { recursive: true });
  if (existsSync(file)) copyFileSync(file, `${file}.bak`);
  const tmp = `${file}.tmp`;
  writeFileSync(tmp, text.endsWith("\n") ? text : `${text}\n`);
  renameSync(tmp, file);
}

function create(file, key) {
  const template = existsSync(TEMPLATE) ? readFileSync(TEMPLATE, "utf8") : "# [key]\n\n## Log\n";
  save(file, template.replace(/^# .*$/m, `# ${key}`));
}

/** Finds a "## heading" line by its first words, case-insensitively. */
function findSection(lines, heading) {
  const want = heading.trim().toLowerCase();
  return lines.findIndex((l) => {
    const m = /^##\s+(.*)$/.exec(l);
    return !!m && m[1].trim().toLowerCase().startsWith(want);
  });
}

function sectionEnd(lines, start) {
  for (let i = start + 1; i < lines.length; i++) if (/^##\s/.test(lines[i])) return i;
  return lines.length;
}

/** Returns the text with stdin added to, or replacing, one section's body. */
export function editSection(text, heading, body, mode) {
  const lines = text.replace(/\n+$/, "").split("\n");
  const content = body.replace(/\n+$/, "").split("\n");
  let start = findSection(lines, heading);
  if (start < 0) {
    lines.push("", `## ${heading.trim()}`, "");
    start = lines.length - 2;
  }
  let end = sectionEnd(lines, start);
  if (mode === "section") {
    lines.splice(start + 1, end - start - 1, "", ...content, ...(end < lines.length ? [""] : []));
  } else {
    // Append after the section's last non-blank line, dropping the template's "[placeholder]"
    // body the first time.
    let last = end - 1;
    while (last > start && lines[last].trim() === "") last--;
    const body = lines.slice(start + 1, last + 1).join("\n").trim();
    if (/^\[[^\]]*\]$/.test(body)) {
      lines.splice(start + 1, last - start);
      last = start;
    }
    lines.splice(last + 1, 0, ...(last === start ? [""] : []), ...content);
  }
  return `${lines.join("\n")}\n`;
}

function readStdin() {
  const text = readFileSync(0, "utf8");
  if (!text.trim()) throw new Error("nothing on stdin");
  return text;
}

export function main(argv, cwd = process.cwd()) {
  const [key, flag, heading] = argv;
  if (!key) throw new Error("Usage: notes.mjs <key> [--path | --append <heading> | --section <heading> | --write]");
  const file = notesPath(cwd, key);
  if (!existsSync(file)) create(file, key);
  if (flag === undefined) {
    process.stdout.write(`${file}\n\n${readFileSync(file, "utf8")}`);
  } else if (flag === "--path") {
    process.stdout.write(`${file}\n`);
  } else if (flag === "--write") {
    save(file, readStdin());
    process.stdout.write(`Saved ${file}\n`);
  } else if (flag === "--append" || flag === "--section") {
    if (!heading) throw new Error(`${flag} needs a heading, such as Log`);
    save(file, editSection(readFileSync(file, "utf8"), heading, readStdin(), flag.slice(2)));
    process.stdout.write(`Saved ${file} (${flag.slice(2)} ${heading})\n`);
  } else {
    throw new Error(`unknown option ${flag}`);
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  try {
    main(process.argv.slice(2));
  } catch (err) {
    process.stderr.write(`notes: ${err.message}\n`);
    process.exitCode = 1;
  }
}
