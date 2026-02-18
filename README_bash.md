# c2v Converter

`converter.sh` is a Bash + `ffmpeg` media utility that supports both:
- Interactive terminal mode (menu-driven)
- Non-interactive CLI mode (for calling from other scripts/code)

## Requirements

- Bash
- `ffmpeg`
- `ffprobe`

## Run

Interactive:
```bash
bash converter.sh
```

CLI:
```bash
bash converter.sh <key> [options]
```

Help:
```bash
bash converter.sh -h
bash converter.sh --help
```

## Supported Keys

- `t` image + first 10s of audio to video (with normalization)
- `a` image + full audio to video (with normalization)
- `af` image + full audio to video (no normalization filter)
- `te` trim end at timecode
- `tb` trim beginning from timecode
- `s` split at timecode
- `ss` split + swap
- `na` normalize audio to `*_norm.mp3`
- `ra` reencode audio to `*_reencoded.mp3`
- `ex` extract portion (`--start` to `--end`)
- `m` merge from concat list file

## CLI Usage

### Image + audio to video
```bash
bash converter.sh t  --image cover.jpg --audio input.mp3 --output out.mp4
bash converter.sh a  --image cover.jpg --audio input.mp3 --output out.mp4
bash converter.sh af --image cover.jpg --audio input.mp3 --output out.mp4
```

### Trim / split / swap
```bash
bash converter.sh te --input input.mp3 --time 00:00:10
bash converter.sh tb --input input.mp4 --time 00:00:10
bash converter.sh s  --input input.mp3 --time 00:00:10
bash converter.sh ss --input input.mp4 --time 00:00:10
```

### Audio processing
```bash
bash converter.sh na --input input.mp3
bash converter.sh ra --input input.mp3
```

### Extract
```bash
bash converter.sh ex --input input.mp3 --start 00:00 --end 00:30
```

### Merge
```bash
bash converter.sh m --list list.txt --output merged.mp3
```

`list.txt` format:
```txt
file 'part1.mp3'
file 'part2.mp3'
```

## Notes

- Timecode format: `MM:SS` or `HH:MM:SS`
- Audio/video lists in interactive mode show duration as `HH:MM:SS`
- Long filenames are truncated to keep table alignment stable

## Tests

Run all tests:
```bash
bash tests/run_all.sh
```

Individual suites:
```bash
bash tests/test_timecode.sh
bash tests/test_converter_ops.sh
bash tests/test_startup_checks.sh
bash tests/test_cli_args.sh
```
