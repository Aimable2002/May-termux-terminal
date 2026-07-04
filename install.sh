#!/usr/bin/env bash
# install.sh — sets up MAY on Termux (Android) or a normal PC shell, then
# clones, installs, and launches the MAY9 signal bot.
# Usage: curl -fsSL https://may.dev/install | bash
set -euo pipefail

MAY_TERMINAL_REPO_URL="https://github.com/Aimable2002/May-termux-terminal.git"
BOT_REPO_URL="https://github.com/May-DeFi/May_perp_bot_example.git"

INSTALL_PREFIX="${MAY_PREFIX:-$HOME/.local/share/may}"
TERMINAL_SRC_DIR="$INSTALL_PREFIX/terminal-src"
BOT_SRC_DIR="$INSTALL_PREFIX/may9bot-src"
BOT_APP_DIR="$BOT_SRC_DIR/may9bot"

echo "== Installing MAY =="

is_termux() {
  [ -n "${PREFIX:-}" ] && echo "$PREFIX" | grep -q "com.termux"
}

# ---- 0. profile file must exist BEFORE anything else runs ------------------
PROFILE_FILE="$HOME/.bashrc"
[ -n "${ZSH_VERSION:-}" ] && PROFILE_FILE="$HOME/.zshrc"
touch "$PROFILE_FILE"

# ---- 1. dependencies --------------------------------------------------------
if is_termux; then
  echo "Detected: Termux (Android)"
  pkg update -y
  pkg install -y git python curl
elif command -v apt >/dev/null 2>&1; then
  echo "Detected: Linux (apt)"
  sudo apt update
  sudo apt install -y git python3 python3-pip curl
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

# ---- 3. get the MAY terminal scripts onto disk ------------------------------
# FIX: previously this assumed bin/ and lib/ sat next to this script on disk
# via `$(dirname "${BASH_SOURCE[0]}")`. That breaks silently under the
# documented `curl -fsSL ... | bash` install method, because BASH_SOURCE[0]
# is empty when a script is piped into bash (no file on disk to point to) —
# dirname then resolves to ".", i.e. whatever directory the user happened to
# be sitting in, not the actual repo. So bin/ never got copied correctly and
# `may` was never actually reachable afterward.
#
# Fix: always git clone the terminal repo directly into the install prefix.
# This works identically whether install.sh was piped or run from a local
# checkout, since it no longer depends on its own on-disk location at all.

mkdir -p "$INSTALL_PREFIX"
if [ -d "$TERMINAL_SRC_DIR/.git" ]; then
  echo "MAY terminal source already present — updating..."
  git -C "$TERMINAL_SRC_DIR" pull --ff-only
else
  echo "Cloning MAY terminal source..."
  git clone --depth 1 "$MAY_TERMINAL_REPO_URL" "$TERMINAL_SRC_DIR"
fi

cp -r "$TERMINAL_SRC_DIR/bin" "$TERMINAL_SRC_DIR/lib" "$INSTALL_PREFIX/"
chmod +x "$INSTALL_PREFIX"/bin/*

BIN_LINK_DIR="$INSTALL_PREFIX/bin"

# ---- 4. shell profile wiring -------------------------------------------------
if ! grep -q "MAY_INIT" "$PROFILE_FILE" 2>/dev/null; then
  {
    echo ""
    echo "# MAY_INIT"
    echo "export PATH=\"$BIN_LINK_DIR:\$PATH\""
    echo "export PATH=\"\$HOME/.opencode/bin:\$PATH\""
    echo "alias menu='may'"
  } >> "$PROFILE_FILE"
fi
# Also export for the rest of *this* run, so the bot launch below works
# immediately without requiring a new shell first.
export PATH="$BIN_LINK_DIR:$PATH"

# ---- 5. clone + install the MAY9 signal bot ---------------------------------
echo
echo "== Setting up MAY9 signal bot =="
if [ -d "$BOT_SRC_DIR/.git" ]; then
  echo "Bot source already present — updating..."
  git -C "$BOT_SRC_DIR" pull --ff-only
else
  echo "Cloning MAY9 signal bot..."
  git clone --depth 1 "$BOT_REPO_URL" "$BOT_SRC_DIR"
fi

cd "$BOT_APP_DIR"
if ! pip3 install -r requirements.txt 2>/tmp/may-install-pip.log; then
  echo "Plain pip install failed (likely externally-managed environment)."
  echo "Retrying with --break-system-packages..."
  pip3 install -r requirements.txt --break-system-packages
fi

echo
echo "Install complete."
echo "Open a new shell (or run: source $PROFILE_FILE) so 'may' stays on PATH."
echo "From then on:"
echo "  may config     # set up your API key"
echo "  may trading    # relaunch the MAY9 signal bot any time"
echo "  may            # open the menu"

# ---- 6. launch the bot now ---------------------------------------------------
echo
echo "Launching MAY9 signal bot..."
cd "$BOT_APP_DIR"
exec python3 may9bot.py
