#!/usr/bin/env bash
# Install pre-commit hooks so secret and safety checks run before every commit.
# Run once after clone: ./scripts/setup-hooks.sh
# These hooks can be bypassed with `git commit --no-verify`, but CI will still run the same checks and block the push.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

if ! command -v pre-commit &>/dev/null; then
  echo "pre-commit is not installed. Install it with:"
  echo "  pip install pre-commit   # or: brew install pre-commit"
  exit 1
fi

pre-commit install --install-hooks
echo "Pre-commit hooks installed. They will run on 'git commit'."
echo "To run manually: pre-commit run --all-files"
