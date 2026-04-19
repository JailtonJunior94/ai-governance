#!/usr/bin/env bash
# Wrapper: delega para scripts/validators/validate-task-evidence.sh (localizacao canonica).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec bash "$SCRIPT_DIR/../../scripts/validators/validate-task-evidence.sh" "$@"
