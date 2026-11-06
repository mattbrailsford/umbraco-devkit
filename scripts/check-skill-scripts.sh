#!/usr/bin/env bash
# Runs the tests for the code the plugin ships: scripts inside skills (today, markdown-preview's
# preview server and feature-design's mockup style check), the plugin's hooks and its
# pre-review checks. They're the only parts of the plugin that are code rather than Markdown,
# so a broken change wouldn't show up anywhere else until someone used it.
#
# Standard-library Python only, and no network: GitHub's renderer is swapped for a stand-in.
# The page-script parse check and the hook and check tests run only when node is installed.
#
# Usage: scripts/check-skill-scripts.sh
# Exit code: 0 if every test passes, 1 if something needs a look.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

python3 -m unittest discover -s scripts/tests
