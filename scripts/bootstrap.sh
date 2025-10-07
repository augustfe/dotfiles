#!/usr/bin/env bash
# Minimal bootstrap script to install Homebrew and fish before running the Fish-based setup.

set -euo pipefail

if [[ "${OSTYPE:-}" != darwin* ]]; then
  echo "[bootstrap] This script is intended for macOS systems." >&2
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "[bootstrap] Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "[bootstrap] Homebrew already installed."
fi

if command -v /opt/homebrew/bin/brew >/dev/null 2>&1; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif command -v /usr/local/bin/brew >/dev/null 2>&1; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

if ! command -v fish >/dev/null 2>&1; then
  echo "[bootstrap] Installing fish via Homebrew..."
  brew install fish
else
  echo "[bootstrap] fish already installed."
fi

cat <<'EOF'
[bootstrap] Ready! Launch the Fish setup with:
  fish scripts/setup.fish
EOF
