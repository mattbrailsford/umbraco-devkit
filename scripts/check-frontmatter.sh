#!/usr/bin/env bash
# Checks the frontmatter of every skill and agent. A header that doesn't parse, a name that
# doesn't match its folder or file, or an over-long description can make Claude Code skip the
# skill or agent without any error, so nothing else in the repo would catch it.
#
# Checks: the file opens with a `---` block that parses as YAML; `name` matches the skill's
# folder or the agent's file name; `description` is present and at most 1024 characters;
# `argument-hint`, if present, parses as text rather than a list.
#
# Usage: scripts/check-frontmatter.sh
# Exit code: 0 if every header is valid, 1 if something needs a look.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

plugin_dir="plugins/umbraco-devkit"

ruby -ryaml - "$plugin_dir"/skills/*/SKILL.md "$plugin_dir"/agents/*.md <<'RUBY'
max_description = 1024
problems = 0

ARGV.each do |path|
  text = File.read(path)
  match = text.match(/\A---\n(.*?)\n---\n/m)
  unless match
    puts "#{path}: no frontmatter block at the top of the file"
    problems += 1
    next
  end

  begin
    data = YAML.safe_load(match[1])
  rescue Psych::SyntaxError => e
    puts "#{path}: frontmatter doesn't parse (#{e.message})"
    problems += 1
    next
  end

  unless data.is_a?(Hash)
    puts "#{path}: frontmatter isn't a key/value block"
    problems += 1
    next
  end

  expected = if File.basename(path) == "SKILL.md"
    File.basename(File.dirname(path))
  else
    File.basename(path, ".md")
  end
  if data["name"] != expected
    puts "#{path}: name is #{data["name"].inspect}, expected #{expected.inspect}"
    problems += 1
  end

  # An unquoted hint like `[file, optional]` parses as a YAML list, and Claude Code then
  # shows it joined with commas, or as `[object Object]` if it holds a `key: value`.
  if data.key?("argument-hint") && !data["argument-hint"].is_a?(String)
    puts "#{path}: argument-hint parses as #{data["argument-hint"].class}, not text; wrap it in quotes"
    problems += 1
  end

  description = data["description"].to_s.strip
  if description.empty?
    puts "#{path}: description is missing"
    problems += 1
  elsif description.length > max_description
    puts "#{path}: description is #{description.length} characters, max #{max_description}"
    problems += 1
  end
end

if problems.zero?
  puts "Every skill and agent header parses, names match, and descriptions fit."
  exit 0
else
  exit 1
end
RUBY
