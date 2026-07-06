#!/usr/bin/env bash
# install.sh — sets up MAY (terminal + trading bot) on Termux or a normal
# PC shell. Installs everything needed; does NOT launch the bot — that's
# always a separate, explicit 'may trading' command.
# Usage: curl -fsSL https://may.dev/install | bash
set -euo pipefail

TERMINAL_REPO_URL="https://github.com/Aimable2002/May-termux-terminal.git"
BOT_REPO_URL="https://github.com/May-DeFi/May_perp_bot_example.git"

# Matches MayBootstrap.java's target on Android, so a manual install.sh run
# and the APK's own first-launch auto-setup never create two conflicting
# copies of the terminal scripts.
INSTALL_PREFIX="${MAY_PREFIX:-$HOME/may}"

TERMINAL_SRC_DIR="$HOME/.may-src/May-termux-terminal"
BOT_SRC_DIR="$HOME/.may-trading/May_perp_bot_example"
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
mkdir -p "$(dirname "$TERMINAL_SRC_DIR")"
if [ -d "$TERMINAL_SRC_DIR/.git" ]; then
  echo "MAY terminal source already present — updating..."
  git -C "$TERMINAL_SRC_DIR" pull --ff-only
else
  echo "Cloning MAY terminal source..."
  git clone "$TERMINAL_REPO_URL" "$TERMINAL_SRC_DIR"
fi

mkdir -p "$INSTALL_PREFIX"
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
# Also export for the rest of *this* run, so later steps below can find
# the 'may' commands immediately without requiring a new shell first.
export PATH="$BIN_LINK_DIR:$PATH"

# ---- 5. clone + install the MAY9 trading bot (SETUP ONLY — never launches) --
echo
echo "== Setting up MAY9 trading bot =="
mkdir -p "$(dirname "$BOT_SRC_DIR")"
if [ -d "$BOT_SRC_DIR/.git" ]; then
  echo "Bot source already present — updating..."
  git -C "$BOT_SRC_DIR" pull --ff-only
else
  echo "Cloning MAY9 trading bot..."
  git clone --depth 1 "$BOT_REPO_URL" "$BOT_SRC_DIR"
fi

PIP_LOG="$(mktemp)"
if ! (cd "$BOT_APP_DIR" && pip3 install -q -r requirements.txt 2>"$PIP_LOG"); then
  if grep -q "externally-managed-environment" "$PIP_LOG" 2>/dev/null; then
    echo "System Python is externally managed — retrying with --break-system-packages..."
    (cd "$BOT_APP_DIR" && pip3 install -q -r requirements.txt --break-system-packages)
  else
    cat "$PIP_LOG" >&2
    rm -f "$PIP_LOG"
    exit 1
  fi
fi
rm -f "$PIP_LOG"

# Deliberately no bot launch here. Starting a trading bot is never a side
# effect of running/re-running an installer — it's always an explicit,
# separate action via 'may trading', so nothing ever starts trading
# without someone directly asking for it.

echo
echo "Install complete. Open a new shell (or run: source $PROFILE_FILE), then run:"
echo "  may config     # set up your API key"
echo "  may trading    # launch the MAY9 trading bot"
echo "  may            # open the menu"
