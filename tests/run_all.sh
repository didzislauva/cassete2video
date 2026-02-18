#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

bash "$ROOT/tests/test_timecode.sh"
bash "$ROOT/tests/test_converter_ops.sh"
bash "$ROOT/tests/test_startup_checks.sh"
bash "$ROOT/tests/test_cli_args.sh"

echo
echo "All test suites passed."
