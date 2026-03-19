#!/usr/bin/env bash
set -euo pipefail

: "${IOS_SDK:?}"

exec xcrun --sdk "$IOS_SDK" ar "$@"
