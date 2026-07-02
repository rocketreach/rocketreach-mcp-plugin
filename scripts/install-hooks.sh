#!/usr/bin/env bash
#
# Point git at the version-controlled hooks in .githooks/.
# Run once after cloning:
#   ./scripts/install-hooks.sh
#
# To undo:
#   git config --unset core.hooksPath
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
hooks_dir="$repo_root/.githooks"

existing="$(git config --get core.hooksPath || true)"
if [ -n "$existing" ] && [ "$existing" != "$hooks_dir" ] && [ "$existing" != ".githooks" ]; then
  echo "Warning: core.hooksPath is already set to '$existing'." >&2
  echo "It will be replaced by '$hooks_dir'; hooks under '$existing' will stop running." >&2
fi

git config core.hooksPath "$hooks_dir"
chmod +x "$hooks_dir"/*

echo "Installed git hooks (core.hooksPath -> $hooks_dir)."
echo "Note: this overrides .git/hooks for this clone. Undo with: git config --unset core.hooksPath"
echo "Secret scanning runs on commit and requires trufflehog:"
echo "  https://github.com/trufflesecurity/trufflehog#installation"
