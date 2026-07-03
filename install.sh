#!/usr/bin/env bash
# install.sh — sets up MAY on Termux (Android) or a normal PC shell.
# Usage: curl -fsSL https://may.dev/install | bash
set -euo pipefail

INSTALL_SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_PREFIX="${MAY_PREFIX:-$HOME/.local/share/may}"

echo "== Installing MAY =="

is_termux() {
  [ -n "${PREFIX:-}" ] && echo "$PREFIX" | grep -q "com.termux"
}

# ---- 1. dependencies --------------------------------------------------------

# ---- 1. dependencies --------------------------------------------------------
# Only what MAY's own scripts strictly require to function at all:
#   - git    : device sync
#   - python3: JSON parsing in lib/common.sh (config + API calls)
#   - curl   : talking to OpenRouter's API
# Nothing else is force-installed — the terminal is still just a terminal.
# OpenCode's own installer (below) handles whatever runtime it needs itself.

if is_termux; then
  echo "Detected: Termux (Android)"
  pkg update -y
  pkg install -y git python curl
elif command -v apt >/dev/null 2>&1; then
  echo "Detected: Linux (apt)"
  sudo apt update
  sudo apt install -y git python3 curl
elif command -v brew >/dev/null 2>&1; then
  echo "Detected: macOS (Homebrew)"
  brew install git python3 curl
else
  echo "Could not detect a supported package manager (pkg/apt/brew)." >&2
  echo "Please install git, python3 and curl manually, then re-run this script." >&2
  exit 1
fi

# ---- 2. OpenCode ------------------------------------------------------------

if ! command -v opencode >/dev/null 2>&1; then
  echo "Installing OpenCode..."
  curl -fsSL https://opencode.ai/install | bash || \
    echo "OpenCode install failed — you can retry later, agent mode just won't work until it's installed."
fi

# ---- 3. copy the script suite into place -----------------------------------

mkdir -p "$INSTALL_PREFIX"
cp -r "$INSTALL_SRC_DIR/bin" "$INSTALL_SRC_DIR/lib" "$INSTALL_PREFIX/"
chmod +x "$INSTALL_PREFIX"/bin/*

# NOTE: we deliberately do NOT symlink these into ~/.local/bin or
# $PREFIX/bin. Each script locates lib/common.sh relative to its own real
# path, and a symlink elsewhere would break that lookup. Instead we add the
# real install directory straight to PATH below.
BIN_LINK_DIR="$INSTALL_PREFIX/bin"

# ---- 4. shell profile wiring -------------------------------------------------

PROFILE_FILE="$HOME/.bashrc"
[ -n "${ZSH_VERSION:-}" ] && PROFILE_FILE="$HOME/.zshrc"

if ! grep -q "MAY_INIT" "$PROFILE_FILE" 2>/dev/null; then
  {
    echo ""
    echo "# MAY_INIT"
    echo "export PATH=\"$BIN_LINK_DIR:\$PATH\""
    echo "alias menu='may'"
  } >> "$PROFILE_FILE"
fi

echo
echo "Install complete."
echo "Open a new shell (or run: source $PROFILE_FILE), then run:"
echo "  may config     # set up your API key"
echo "  may            # open the menu"