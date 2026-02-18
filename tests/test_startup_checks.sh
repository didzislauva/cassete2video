#!/usr/bin/env bash

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS_COUNT=0
FAIL_COUNT=0

pass() {
    echo "PASS: $1"
    ((PASS_COUNT++))
}

fail() {
    echo "FAIL: $1"
    ((FAIL_COUNT++))
}

run_capture() {
    local out_file rc
    out_file="$(mktemp)"
    "$@" >"$out_file" 2>&1
    rc=$?
    cat "$out_file"
    rm -f "$out_file"
    return $rc
}

test_missing_ffmpeg() {
    local out rc
    out="$(PATH=/tmp/does-not-exist /usr/bin/bash "$REPO_ROOT/converter.sh" 2>&1 || true)"
    rc=$?

    # rc is from 'true' due || true, so assert by content.
    if [[ "$out" == *"ffmpeg is not installed or not in PATH"* ]]; then
        pass "missing ffmpeg check"
    else
        fail "missing ffmpeg check"
    fi
}

test_missing_ffprobe_only() {
    local fake_bin tmp out
    tmp="$(mktemp -d)"
    fake_bin="$tmp/ffmpeg"

    cat > "$fake_bin" <<'SH'
#!/usr/bin/env sh
exit 0
SH
    chmod +x "$fake_bin"

    out="$(PATH="$tmp" /usr/bin/bash "$REPO_ROOT/converter.sh" 2>&1 || true)"
    rm -rf "$tmp"

    if [[ "$out" == *"ffprobe is not installed or not in PATH"* ]]; then
        pass "missing ffprobe check"
    else
        fail "missing ffprobe check"
    fi
}

main() {
    test_missing_ffmpeg
    test_missing_ffprobe_only

    echo
    echo "Passed: $PASS_COUNT"
    echo "Failed: $FAIL_COUNT"

    ((FAIL_COUNT == 0))
}

main "$@"
