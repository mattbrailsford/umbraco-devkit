#!/usr/bin/env bash
# Runs the tests for the scripts that ship inside skills (today, markdown-preview's preview
# server). They're the one part of the plugin that's code rather than Markdown, so a broken
# change wouldn't show up anywhere else until someone opened a preview.
#
# Standard-library Python only, and no network: GitHub's renderer is swapped for a stand-in.
# The page-script parse check runs only when node is installed.
#
# Usage: scripts/check-skill-scripts.sh
# Exit code: 0 if every test passes, 1 if something needs a look.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

python3 -m unittest discover -s scripts/tests
