#!/usr/bin/env bash
# install.sh — set up the agentic-workspace CLI.
#
# 1. Asks where to store config (default: ~/.agentic-workspace/).
# 2. Writes config.json with the absolute repo path and reports path.
# 3. Symlinks bin/aw → ~/.local/bin/aw (idempotent).
#
# Re-run after moving the repo to refresh repo_path in config.json.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO_ROOT/bin/aw"
DST_DIR="$HOME/.local/bin"
DST="$DST_DIR/aw"
DEFAULT_CONFIG_DIR="$HOME/.agentic-workspace"

if [ ! -f "$SRC" ]; then
  echo "Error: $SRC not found. Run install.sh from the repo root." >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required but not installed." >&2
  echo "Install it via your package manager (e.g. apt install jq, brew install jq)." >&2
  exit 1
fi

# --- 1. Ask for config dir (default ~/.agentic-workspace/) ------------------

# Allow non-interactive runs by accepting AW_CONFIG_DIR env var.
if [ -n "${AW_CONFIG_DIR:-}" ]; then
  CONFIG_DIR="$AW_CONFIG_DIR"
elif [ -t 0 ]; then
  read -r -p "Config directory [$DEFAULT_CONFIG_DIR]: " CONFIG_DIR
  CONFIG_DIR="${CONFIG_DIR:-$DEFAULT_CONFIG_DIR}"
else
  CONFIG_DIR="$DEFAULT_CONFIG_DIR"
fi

# Expand ~
CONFIG_DIR="${CONFIG_DIR/#\~/$HOME}"

CONFIG_FILE="$CONFIG_DIR/config.json"
REPORTS_PATH="$CONFIG_DIR/reports.jsonl"

# --- 2. Write config.json ---------------------------------------------------

mkdir -p "$CONFIG_DIR"
jq -n --arg repo "$REPO_ROOT" --arg reports "$REPORTS_PATH" \
  '{repo_path: $repo, reports_path: $reports}' > "$CONFIG_FILE"
[ -f "$REPORTS_PATH" ] || touch "$REPORTS_PATH"

echo "Config written: $CONFIG_FILE"
echo "  repo_path:    $REPO_ROOT"
echo "  reports_path: $REPORTS_PATH"

# --- 3. Symlink ~/.local/bin/aw → bin/aw ------------------------------------

chmod +x "$SRC"
mkdir -p "$DST_DIR"

if [ -L "$DST" ] && [ "$(readlink "$DST")" = "$SRC" ]; then
  echo "Symlink already in place: $DST → $SRC"
elif [ -L "$DST" ]; then
  # Existing symlink points elsewhere — likely an old install. Replace it.
  ln -sf "$SRC" "$DST"
  echo "Updated symlink: $DST → $SRC"
elif [ -e "$DST" ]; then
  echo "Error: $DST exists and is not a symlink." >&2
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
  echo ""
  echo "Run 'aw help' to verify."
fi
