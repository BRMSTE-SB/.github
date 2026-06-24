#!/usr/bin/env bash
# Back-compat: full Metrallium verification now lives in verify-metrallium-ops.sh
exec "$(cd "$(dirname "$0")" && pwd)/verify-metrallium-ops.sh" "$@"
