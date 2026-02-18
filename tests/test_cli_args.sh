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

run_case() {
    local name="$1"
    shift
    local tmp_dir
    tmp_dir="$(mktemp -d)"

    (
        cd "$tmp_dir" || exit 1
        ffmpeg -hide_banner -loglevel error -f lavfi -i sine=frequency=1000:sample_rate=44100 -t 3 -c:a libmp3lame input.mp3 >/dev/null 2>&1 || exit 1
        ffmpeg -hide_banner -loglevel error -f lavfi -i testsrc=size=64x64:rate=25 -f lavfi -i sine=frequency=440:sample_rate=44100 -t 3 -c:v libx264 -pix_fmt yuv420p -c:a aac input.mp4 >/dev/null 2>&1 || exit 1
        ffmpeg -hide_banner -loglevel error -f lavfi -i color=c=red:s=101x99 -frames:v 1 odd.jpg >/dev/null 2>&1 || exit 1
        "$@"
    ) >/dev/null 2>&1

    if [[ $? -eq 0 ]]; then
        pass "$name"
    else
        fail "$name"
    fi

    rm -rf "$tmp_dir"
}

case_t() {
    /usr/bin/bash "$REPO_ROOT/converter.sh" t --image odd.jpg --audio input.mp3 --output out.mp4 || return 1
    [[ -f out.mp4 ]]
}

case_trim() {
    /usr/bin/bash "$REPO_ROOT/converter.sh" te --input input.mp3 --time 00:00:01 || return 1
    [[ -f input_trimmed_end.mp3 ]]
}

case_extract() {
    /usr/bin/bash "$REPO_ROOT/converter.sh" ex --input input.mp3 --start 00:00 --end 00:01 || return 1
    [[ -f input_portion1.mp3 ]]
}

case_na_ra() {
    /usr/bin/bash "$REPO_ROOT/converter.sh" na --input input.mp3 || return 1
    /usr/bin/bash "$REPO_ROOT/converter.sh" ra --input input.mp3 || return 1
    [[ -f input_norm.mp3 && -f input_reencoded.mp3 ]]
}

case_merge() {
    cp input.mp3 a.mp3
    cp input.mp3 b.mp3
    cat > list.txt <<'LST'
file 'a.mp3'
file 'b.mp3'
LST
    /usr/bin/bash "$REPO_ROOT/converter.sh" m --list list.txt --output merged.mp3 || return 1
    [[ -f merged.mp3 ]]
}

main() {
    run_case "cli t image+audio" case_t
    run_case "cli te trim end" case_trim
    run_case "cli ex extract" case_extract
    run_case "cli na+ra audio ops" case_na_ra
    run_case "cli m merge" case_merge
    /usr/bin/bash "$REPO_ROOT/converter.sh" -h >/dev/null 2>&1 && pass "cli -h help" || fail "cli -h help"
    /usr/bin/bash "$REPO_ROOT/converter.sh" --help >/dev/null 2>&1 && pass "cli --help help" || fail "cli --help help"

    echo
    echo "Passed: $PASS_COUNT"
    echo "Failed: $FAIL_COUNT"
    ((FAIL_COUNT == 0))
}

main "$@"
