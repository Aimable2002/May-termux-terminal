#!/usr/bin/env bash
# common.sh — shared functions used by every may-* command.
# Sourced, not executed directly.

set -euo pipefail

MAY_CONFIG_DIR="${MAY_CONFIG_DIR:-$HOME/.config/may}"
MAY_CONFIG_FILE="$MAY_CONFIG_DIR/config.json"
MAY_DEFAULT_BASE_URL="https://openrouter.ai/api/v1"

# ---- dependency checks -----------------------------------------------------

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    echo "Install it and try again (e.g. 'pkg install $cmd' on Termux, 'apt/brew install $cmd' on PC)." >&2
    exit 1
  fi
}

require_cmd curl
require_cmd python3

# ---- config -----------------------------------------------------------------

ensure_config_dir() {
  mkdir -p "$MAY_CONFIG_DIR"
  chmod 700 "$MAY_CONFIG_DIR" 2>/dev/null || true
}

config_exists() {
  [ -f "$MAY_CONFIG_FILE" ]
}

# Reads a single field out of the JSON config file. Empty string if missing.
config_get() {
  local key="$1"
  if ! config_exists; then
    echo ""
    return 0
  fi
  python3 - "$MAY_CONFIG_FILE" "$key" <<'PYEOF'
import json, sys
path, key = sys.argv[1], sys.argv[2]
try:
    with open(path) as f:
        data = json.load(f)
    print(data.get(key, "") or "")
except Exception:
    print("")
PYEOF
}

# Writes/updates the config file with the given key/value pairs.
# Usage: config_set api_key "sk-..." base_url "https://..." default_model "..."
config_set() {
  ensure_config_dir
  python3 - "$MAY_CONFIG_FILE" "$@" <<'PYEOF'
import json, sys, os
path = sys.argv[1]
pairs = sys.argv[2:]
data = {}
if os.path.exists(path):
    try:
        with open(path) as f:
            data = json.load(f)
    except Exception:
        data = {}
for i in range(0, len(pairs), 2):
    data[pairs[i]] = pairs[i + 1]
with open(path, "w") as f:
    json.dump(data, f, indent=2)
os.chmod(path, 0o600)
PYEOF
}

# Resolve our own bin/ directory reliably, regardless of PATH state —
# used as a fallback if 'may-config' isn't found on PATH for some reason.
_MAY_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_MAY_BIN_DIR="$(cd "$_MAY_LIB_DIR/../bin" && pwd)"

# Sets the global $API_KEY. Deliberately NOT meant to be called via
# command substitution ($(...)) — if it needs to run the interactive
# config prompt, that prompt's own output would otherwise get captured
# as part of the "return value" instead of printing to the screen.
require_api_key() {
  local key
  key="$(config_get api_key)"
  if [ -z "$key" ]; then
    echo "No API key set up yet — let's set one up now."
    echo
    if command -v may-config >/dev/null 2>&1; then
      may-config
    elif [ -x "$_MAY_BIN_DIR/may-config" ]; then
      "$_MAY_BIN_DIR/may-config"
    else
      echo "Could not find 'may-config' to run automatically." >&2
      echo "Run it manually, then try again." >&2
      exit 1
    fi
    key="$(config_get api_key)"
    if [ -z "$key" ]; then
      echo "No key was saved — try again with: may config" >&2
      exit 1
    fi
  fi
  API_KEY="$key"
}

get_base_url() {
  local url
  url="$(config_get base_url)"
  if [ -z "$url" ]; then
    echo "$MAY_DEFAULT_BASE_URL"
  else
    echo "$url"
  fi
}

get_default_model() {
  local model
  model="$(config_get default_model)"
  if [ -z "$model" ]; then
    echo "meta-llama/llama-3.1-8b-instruct:free"
  else
    echo "$model"
  fi
}