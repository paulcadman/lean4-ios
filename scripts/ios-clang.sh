#!/usr/bin/env bash
set -euo pipefail

: "${IOS_SDK:?}"

CLANG_PATH="$(xcrun --sdk "$IOS_SDK" -f clang)"

if [[ -n "${CCACHE:-}" ]]; then
  exec "$CCACHE" "$CLANG_PATH" "$@"
else
  exec "$CLANG_PATH" "$@"
fi
