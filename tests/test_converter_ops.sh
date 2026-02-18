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

assert_file_exists() {
    local path="$1"
    local label="$2"
    if [[ -f "$path" ]]; then
        pass "$label"
    else
        fail "$label (missing: $path)"
    fi
}

assert_media_duration_between() {
    local file="$1"
    local min_sec="$2"
    local max_sec="$3"
    local label="$4"
    local raw sec

    raw="$(ffprobe -v error -show_entries format=duration -of default=nokey=1:noprint_wrappers=1 "$file" 2>/dev/null || true)"
    sec="${raw%.*}"
    [[ -z "$sec" ]] && sec=0

    if (( sec >= min_sec && sec <= max_sec )); then
        pass "$label (duration=${sec}s)"
    else
        fail "$label (duration=${sec}s not in ${min_sec}..${max_sec})"
    fi
}

run_in_tmp() {
    local name="$1"
    shift
    local tmp_dir
    tmp_dir="$(mktemp -d)"

    (
        cd "$tmp_dir" || exit 1

        # Fixtures: audio, video+audio, odd-dimension image
        ffmpeg -hide_banner -loglevel error -f lavfi -i sine=frequency=1000:sample_rate=44100 -t 3 -c:a libmp3lame input.mp3 >/dev/null 2>&1 || exit 1
        ffmpeg -hide_banner -loglevel error -f lavfi -i testsrc=size=64x64:rate=25 -f lavfi -i sine=frequency=440:sample_rate=44100 -t 3 -c:v libx264 -pix_fmt yuv420p -c:a aac input.mp4 >/dev/null 2>&1 || exit 1
        ffmpeg -hide_banner -loglevel error -f lavfi -i color=c=red:s=101x99 -frames:v 1 odd.jpg >/dev/null 2>&1 || exit 1

        source "$REPO_ROOT/converter.sh"
        prompt_restart() { :; }
        start() { :; }

        "$@" >/dev/null 2>&1
    )
    local rc=$?

    if (( rc == 0 )); then
        pass "$name"
    else
        fail "$name (rc=$rc)"
    fi

    rm -rf "$tmp_dir"
}

op_image_audio_t() {
    key="t"
    test_or_all <<< $'odd.jpg\ninput.mp3\nout_t\n'
    [[ -f out_t.mp4 ]]
}

op_normalize_audio() {
    normalize_audio <<< $'input.mp3\n'
    [[ -f input_norm.mp3 ]]
}

op_reencode_audio() {
    reencode_audio <<< $'input.mp3\n'
    [[ -f input_reencoded.mp3 ]]
}

op_trim_split_swap_audio() {
    key="te"
    trimSplitSwapFile <<< $'input.mp3\n00:00:01\n'
    [[ -f input_trimmed_end.mp3 ]] || return 1

    key="tb"
    trimSplitSwapFile <<< $'input.mp3\n00:00:01\n'
    [[ -f input_trimmed_beginning.mp3 ]] || return 1

    key="s"
    trimSplitSwapFile <<< $'input.mp3\n00:00:01\n'
    [[ -f input_A.mp3 && -f input_B.mp3 ]] || return 1

    key="ss"
    trimSplitSwapFile <<< $'input.mp3\n00:00:01\n'
    [[ -f input_swapped.mp3 ]]
}

op_trim_split_swap_video() {
    key="te"
    trimSplitSwapFile <<< $'input.mp4\n00:00:01\n'
    [[ -f input_trimmed_end.mp4 ]] || return 1

    key="tb"
    trimSplitSwapFile <<< $'input.mp4\n00:00:01\n'
    [[ -f input_trimmed_beginning.mp4 ]] || return 1

    key="s"
    trimSplitSwapFile <<< $'input.mp4\n00:00:01\n'
    [[ -f input_A.mp4 && -f input_B.mp4 ]] || return 1

    key="ss"
    trimSplitSwapFile <<< $'input.mp4\n00:00:01\n'
    [[ -f input_swapped.mp4 ]]
}

op_merge_execute() {
    cat > list.txt <<'LST'
file 'input.mp3'
file 'input.mp3'
LST
    merge_file_execute <<< $'merged.mp3\n'
    [[ -f merged.mp3 ]]
}

op_list_table_alignment() {
    # Add long names to stress truncation and alignment
    cp input.mp3 "this_is_a_very_very_long_audio_filename_that_should_be_trimmed.mp3"
    cp input.mp4 "this_is_a_very_very_long_video_filename_that_should_be_trimmed.mp4"

    output="$(ask_for_key <<< $'q\n' 2>&1 || true)"

    # Extract table rows beginning with '| ' and ensure each has same visible length.
    mapfile -t rows < <(printf '%s\n' "$output" | awk '/^\| / {print}')
    (( ${#rows[@]} >= 2 )) || return 1

    expected_len=${#rows[0]}
    for row in "${rows[@]}"; do
        [[ ${#row} -eq $expected_len ]] || return 1
    done

    return 0
}

op_duration_expectations() {
    key="te"
    trimSplitSwapFile <<< $'input.mp3\n00:00:01\n'
    assert_media_duration_between "input_trimmed_end.mp3" 1 1 "trimmed_end audio around 1s"

    key="tb"
    trimSplitSwapFile <<< $'input.mp3\n00:00:01\n'
    assert_media_duration_between "input_trimmed_beginning.mp3" 1 3 "trimmed_beginning audio around 2s"
}

main() {
    run_in_tmp "image+audio t flow" op_image_audio_t
    run_in_tmp "normalize_audio flow" op_normalize_audio
    run_in_tmp "reencode_audio flow" op_reencode_audio
    run_in_tmp "trim/split/swap audio flows" op_trim_split_swap_audio
    run_in_tmp "trim/split/swap video flows" op_trim_split_swap_video
    run_in_tmp "merge_file_execute flow" op_merge_execute
    run_in_tmp "table alignment with long filenames" op_list_table_alignment
    run_in_tmp "duration sanity checks" op_duration_expectations

    echo
    echo "Passed: $PASS_COUNT"
    echo "Failed: $FAIL_COUNT"

    ((FAIL_COUNT == 0))
}

main "$@"
