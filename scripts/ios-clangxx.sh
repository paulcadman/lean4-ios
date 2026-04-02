#!/usr/bin/env bash
set -euo pipefail

: "${IOS_SDK:?}"

CLANGXX_PATH="$(xcrun --sdk "$IOS_SDK" -f clang++)"

if [[ -n "${CCACHE:-}" ]]; then
  exec "$CCACHE" "$CLANGXX_PATH" "$@"
else
  exec "$CLANGXX_PATH" "$@"
fi
