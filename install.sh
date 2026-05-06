#!/usr/bin/env bash
# install.sh — add agentic-workspace's bin/ to your shell PATH
#
# Detects bash or zsh, appends an export PATH line to the right rc file.
# Asks for confirmation before writing. Idempotent.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$REPO_ROOT/bin"

if [ ! -x "$BIN_DIR/aw" ]; then
  echo "Making bin/aw executable..."
  chmod +x "$BIN_DIR/aw"
fi

# Detect shell
shell_name="$(basename "${SHELL:-bash}")"
case "$shell_name" in
  bash) rc_file="$HOME/.bashrc" ;;
  zsh)  rc_file="$HOME/.zshrc" ;;
  *)
    echo "Unsupported shell: $shell_name"
    echo "Add this line manually to your shell rc file:"
    echo "  export PATH=\"$BIN_DIR:\$PATH\""
    exit 1
    ;;
esac

export_line="export PATH=\"$BIN_DIR:\$PATH\"  # agentic-workspace"

if grep -qF "$BIN_DIR" "$rc_file" 2>/dev/null; then
  echo "Already installed: $BIN_DIR is in $rc_file"
  echo "Open a new shell or run: source $rc_file"
  exit 0
fi

echo "About to add this line to $rc_file:"
echo ""
echo "  $export_line"
echo ""
read -r -p "Proceed? [y/N] " response
case "$response" in
  [yY][eE][sS]|[yY])
    {
      echo ""
      echo "# agentic-workspace — added by install.sh on $(date '+%Y-%m-%d')"
      echo "$export_line"
    } >> "$rc_file"
    echo "Done. Open a new shell or run: source $rc_file"
    echo "Then verify: aw help"
    ;;
  *)
    echo "Aborted. To install manually, add this line to $rc_file:"
    echo "  $export_line"
    ;;
esac
