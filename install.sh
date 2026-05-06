#!/usr/bin/env bash
# install.sh — make `aw` callable from anywhere.
#
# Strategy: symlink bin/aw → ~/.local/bin/aw (standard XDG user-binary path,
# in PATH by default on most modern Linux/macOS shells). No interactive
# prompt, no shell-rc modification. Idempotent.
# If ~/.local/bin is not in PATH, prints how to add it manually.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO_ROOT/bin/aw"
DST_DIR="$HOME/.local/bin"
DST="$DST_DIR/aw"

if [ ! -f "$SRC" ]; then
  echo "Error: $SRC not found. Run install.sh from the repo root." >&2
  exit 1
fi

chmod +x "$SRC"
mkdir -p "$DST_DIR"

if [ -L "$DST" ] && [ "$(readlink "$DST")" = "$SRC" ]; then
  echo "Already installed: $DST → $SRC"
elif [ -e "$DST" ] || [ -L "$DST" ]; then
  echo "Error: $DST already exists and is not our symlink." >&2
  echo "Remove it manually then re-run: rm $DST" >&2
  exit 1
else
  ln -s "$SRC" "$DST"
  echo "Installed: $DST → $SRC"
fi

if ! echo ":$PATH:" | grep -q ":$DST_DIR:"; then
  cat <<EOF

Note: $DST_DIR is not in your PATH.
Add this line to your shell rc (~/.bashrc or ~/.zshrc):
  export PATH="$DST_DIR:\$PATH"
Or call $SRC directly with its full path.
EOF
else
  echo "Run 'aw help' to verify."
fi
