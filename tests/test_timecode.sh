#!/usr/bin/env bash

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_ROOT/converter.sh"

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

assert_parse_ok() {
    local input="$1"
    local expected="$2"
    local out

    if out="$(parse_timecode_hhmmss "$input")"; then
        if [[ "$out" == "$expected" ]]; then
            pass "parse '$input' -> $expected"
        else
            fail "parse '$input' expected '$expected' got '$out'"
        fi
    else
        fail "parse '$input' returned error, expected '$expected'"
    fi
}

assert_parse_fail() {
    local input="$1"
    local out

    if out="$(parse_timecode_hhmmss "$input" 2>/dev/null)"; then
        fail "parse '$input' unexpectedly succeeded with '$out'"
    else
        pass "parse '$input' fails as expected"
    fi
}

assert_format_ok() {
    local input="$1"
    local expected="$2"
    local out

    out="$(format_seconds_hhmmss "$input")"
    if [[ "$out" == "$expected" ]]; then
        pass "format '$input' -> $expected"
    else
        fail "format '$input' expected '$expected' got '$out'"
    fi
}

assert_fit_ok() {
    local input="$1"
    local width="$2"
    local expected="$3"
    local out

    out="$(fit_to_column "$input" "$width")"
    if [[ "$out" == "$expected" ]]; then
        pass "fit '$input' width=$width -> '$expected'"
    else
        fail "fit '$input' width=$width expected '$expected' got '$out'"
    fi
}

assert_fit_len() {
    local input="$1"
    local width="$2"
    local out

    out="$(fit_to_column "$input" "$width")"
    if (( ${#out} <= width )); then
        pass "fit length '$input' width=$width -> ${#out} <= $width"
    else
        fail "fit length '$input' width=$width -> ${#out} > $width"
    fi
}

assert_separator_ok() {
    local width="$1"
    local out expected

    screen_width="$width"
    out="$(print_screen_separator)"
    expected="$(printf "%*s" "$width" "" | tr " " "=")"

    if [[ "$out" == "$expected" ]]; then
        pass "separator width=$width"
    else
        fail "separator width=$width expected '$expected' got '$out'"
    fi
}

assert_media_duration_ok() {
    local input="$1"
    local expected="$2"
    local out

    out="$(get_media_duration "$input" 2>/dev/null)"
    if [[ "$out" == "$expected" ]]; then
        pass "duration '$input' -> $expected"
    else
        fail "duration '$input' expected '$expected' got '$out'"
    fi
}

run_tests() {
    # Valid MM:SS and HH:MM:SS
    assert_parse_ok "0:0" "00:00:00"
    assert_parse_ok "1:2" "00:01:02"
    assert_parse_ok "12:34" "00:12:34"
    assert_parse_ok "1:02:03" "01:02:03"
    assert_parse_ok "99:59:59" "99:59:59"
    assert_parse_ok "09:08:07" "09:08:07"
    assert_parse_ok "00:00" "00:00:00"
    assert_parse_ok "00:00:00" "00:00:00"
    assert_parse_ok "7:05" "00:07:05"

    # Invalid structure
    assert_parse_fail ""
    assert_parse_fail "12"
    assert_parse_fail "1:2:3:4"
    assert_parse_fail "abc"
    assert_parse_fail " 1:02"
    assert_parse_fail "1:02 "

    # Invalid ranges
    assert_parse_fail "1:60"
    assert_parse_fail "1:2:60"
    assert_parse_fail "00:99:00"
    assert_parse_fail "00:00:99"
    assert_parse_fail "100:00:00"

    # Invalid tokens
    assert_parse_fail "1:a"
    assert_parse_fail "a:1"
    assert_parse_fail "-1:10"

    # format_seconds_hhmmss
    assert_format_ok "0" "00:00:00"
    assert_format_ok "59" "00:00:59"
    assert_format_ok "60" "00:01:00"
    assert_format_ok "3661" "01:01:01"
    assert_format_ok "86399" "23:59:59"
    assert_format_ok "" "00:00:00"
    assert_format_ok "abc" "00:00:00"

    # fit_to_column
    assert_fit_ok "short" 10 "short"
    assert_fit_ok "exactwidth" 10 "exactwidth"
    assert_fit_ok "abcdefghijk" 10 "abcdefg..."
    assert_fit_ok "abcd" 3 "abc"
    assert_fit_ok "ab" 2 "ab"
    assert_fit_ok "abcdef" 1 "a"
    assert_fit_ok "abcdef" 0 ""
    assert_fit_ok "" 10 ""
    assert_fit_len "very-long-filename-with-many-characters.mp3" 34
    assert_fit_len "very-long-filename-with-many-characters.mp3" 10
    assert_fit_len "abcd" 3
    assert_fit_len "abcd" 0

    # print_screen_separator
    assert_separator_ok 1
    assert_separator_ok 10
    assert_separator_ok 37

    # get_media_duration integration tests
    tmp_dir="$(mktemp -d)"
    tmp_wav="$tmp_dir/one_sec.wav"
    # Create a deterministic 1-second silent audio fixture.
    ffmpeg -hide_banner -loglevel error -f lavfi -i anullsrc=r=44100:cl=mono -t 1 "$tmp_wav" >/dev/null 2>&1
    assert_media_duration_ok "$tmp_wav" "00:00:01"
    assert_media_duration_ok "$tmp_dir/does_not_exist.wav" "00:00:00"
    rm -rf "$tmp_dir"
}

run_tests

echo
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"

if ((FAIL_COUNT > 0)); then
    exit 1
fi

exit 0
