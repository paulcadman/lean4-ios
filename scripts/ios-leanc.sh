#!/usr/bin/env bash
set -euo pipefail

: "${IOS_SDK:?}"
: "${IOS_TARGET:?}"
: "${IOS_DEPLOYMENT_TARGET:?}"
: "${LEAN_RUNTIME_INCLUDE:?}"
: "${LEAN_STAGE0_INCLUDE:?}"
: "${LEAN_SRC_INCLUDE:?}"

SDK_PATH="$(xcrun --sdk "$IOS_SDK" --show-sdk-path)"

exec xcrun --sdk "$IOS_SDK" clang \
  -target "$IOS_TARGET" \
  -isysroot "$SDK_PATH" \
  -mios-version-min="$IOS_DEPLOYMENT_TARGET" \
  -I"$LEAN_RUNTIME_INCLUDE" \
  -I"$LEAN_STAGE0_INCLUDE" \
  -I"$LEAN_SRC_INCLUDE" \
  "$@"
