#!/bin/bash

# Enable extended globbing for pattern matching
shopt -s nullglob

# Set terminal size (optional, works if terminal supports it)
screen_width=120
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    printf '\e[8;40;%dt' "$screen_width"
fi

# Color definitions for ANSI escape sequences
colorYellow='\e[93m'
colorGreen='\e[92m'
colorCyan='\e[96m'
colorReset='\e[0m'
colorRed='\e[91m'

# Column width for media table (duration + filename)
max_length=34
NON_INTERACTIVE=0

format_seconds_hhmmss() {
    local total_seconds="$1"
    local hours minutes seconds

    if [[ -z "$total_seconds" || ! "$total_seconds" =~ ^[0-9]+$ ]]; then
        total_seconds=0
    fi

    hours=$((total_seconds / 3600))
    minutes=$(((total_seconds % 3600) / 60))
    seconds=$((total_seconds % 60))
    printf "%02d:%02d:%02d" "$hours" "$minutes" "$seconds"
}

get_media_duration() {
    local input_file="$1"
    local duration_raw duration_seconds

    duration_raw=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$input_file")
    duration_seconds="${duration_raw%.*}"
    format_seconds_hhmmss "$duration_seconds"
}

fit_to_column() {
    local value="$1"
    local width="$2"

    if (( ${#value} > width )); then
        if (( width > 3 )); then
            value="${value:0:$((width - 3))}..."
        else
            value="${value:0:$width}"
        fi
    fi

    printf "%s" "$value"
}

print_screen_separator() {
    printf "%*s\n" "$screen_width" "" | tr " " "="
}

parse_timecode_hhmmss() {
    local input="$1"
    local hours minutes seconds
    local -a time_parts

    IFS=':' read -ra time_parts <<< "$input"

    if [[ ${#time_parts[@]} -eq 3 ]]; then
        hours="${time_parts[0]}"
        minutes="${time_parts[1]}"
        seconds="${time_parts[2]}"
    elif [[ ${#time_parts[@]} -eq 2 ]]; then
        hours="0"
        minutes="${time_parts[0]}"
        seconds="${time_parts[1]}"
    else
        return 1
    fi

    if [[ ! "$hours" =~ ^[0-9]{1,2}$ || ! "$minutes" =~ ^[0-9]{1,2}$ || ! "$seconds" =~ ^[0-9]{1,2}$ ]]; then
        return 1
    fi

    if ((10#$minutes > 59 || 10#$seconds > 59)); then
        return 1
    fi

    printf "%02d:%02d:%02d" "$((10#$hours))" "$((10#$minutes))" "$((10#$seconds))"
}

start() {
    clear

    while true; do
        ask_for_key
    done
}

print_main_menu() {
    print_screen_separator
    echo "Program available media work with didzis@lauvadidzis.com"
    print_screen_separator
    echo
    echo "Possible keys to proceed:"
    echo
    echo -e "${colorCyan}t ${colorReset}: first 10 seconds (with audio normalization),"
    echo -e "${colorYellow}a ${colorReset}: full MP3 to video (with sound normalization),"
    echo -e "${colorCyan}af${colorReset}: fast full MP3 to video (no sound normalization),"
    echo -e "${colorYellow}s ${colorReset}: split media file,"
    echo -e "${colorCyan}m ${colorReset}: merge media files in filelist ${colorCyan}list.txt${colorReset},"
    echo -e "${colorYellow}te${colorReset}: trim the end of the media files from certain timecode,"
    echo -e "${colorCyan}tb${colorReset}: trim the beginning of the media files from certain timecode,"
    echo -e "${colorYellow}ss${colorReset}: split and swap media at certain timecode,"
    echo -e "${colorCyan}na${colorReset}: extract and normalize audio stream,"
    echo -e "${colorYellow}ex${colorReset}: extract a portion of media file,"
    echo -e "${colorCyan}ra${colorReset}: reencode mp3,"
    echo -e "${colorYellow}r${colorReset} : refresh the file list,"
    echo -e "${colorCyan}q ${colorReset}: quit."
    echo
}

print_media_table_header() {
    print_screen_separator
    echo -e "File list for available media work with ${colorGreen}ffmpeg${colorReset}"
    echo
    printf "| %-${max_length}s | %-${max_length}s | %-${max_length}s |\n" "Images" "Audio (HH:MM:SS)" "Video (HH:MM:SS)"
    printf '|-%-*s-|-%-*s-|-%-*s-|\n' "$max_length" "$(printf '%*s' "$max_length" '' | tr ' ' '-')" "$max_length" "$(printf '%*s' "$max_length" '' | tr ' ' '-')" "$max_length" "$(printf '%*s' "$max_length" '' | tr ' ' '-')"
    echo
}

load_media_arrays() {
    img_files=(*.jpg *.jpeg *.png *.gif *.bmp *.tiff *.tif)
    aud_files=(*.mp3 *.wav *.wma *.aac *.flac *.ogg *.m4a)
    vid_files=(*.mp4 *.avi *.mkv *.mov *.wmv *.flv *.mpeg *.mpg *.webm)
}

media_table_cell() {
    local type="$1"
    local filename="$2"
    local cell_text

    case "$type" in
        image) cell_text="$filename" ;;
        audio|video) cell_text="[$(get_media_duration "$filename")] $filename" ;;
        *) cell_text="" ;;
    esac

    fit_to_column "$cell_text" "$max_length"
}

print_media_table_rows() {
    local img_count aud_count vid_count max_count
    local i img_display aud_display vid_display

    img_count=${#img_files[@]}
    aud_count=${#aud_files[@]}
    vid_count=${#vid_files[@]}

    max_count=$img_count
    [[ $aud_count -gt $max_count ]] && max_count=$aud_count
    [[ $vid_count -gt $max_count ]] && max_count=$vid_count

    for ((i=0; i<max_count; i++)); do
        img_display=""
        aud_display=""
        vid_display=""

        [[ $i -lt $img_count ]] && img_display="$(media_table_cell image "${img_files[$i]}")"
        [[ $i -lt $aud_count ]] && aud_display="$(media_table_cell audio "${aud_files[$i]}")"
        [[ $i -lt $vid_count ]] && vid_display="$(media_table_cell video "${vid_files[$i]}")"

        printf "| %-${max_length}s | %-${max_length}s | %-${max_length}s |\n" "$img_display" "$aud_display" "$vid_display"
    done
}

dispatch_main_key() {
    case "$key" in
        "t") echo "You selected t: First 10 seconds."; test_or_all ;;
        "a") echo "You selected a: Full MP3. With sound normalization filter."; test_or_all ;;
        "af") echo "You selected af: Fast Full MP3. Without sound normalization."; test_or_all ;;
        "s") echo "You selected s: Split file."; trimSplitSwapFile ;;
        "m") echo "You selected m: Merge files from list."; merge_files ;;
        "te") echo "You selected te: Trim end in file."; trimSplitSwapFile ;;
        "tb") echo "You selected tb: Trim beginning in file."; trimSplitSwapFile ;;
        "ss") echo "You selected ss: Split, swap and merge."; trimSplitSwapFile ;;
        "na") echo "You selected na: Normalize audio."; normalize_audio ;;
        "ex") echo "You selected ex: Extracting a portion."; extract_portion ;;
        "r") echo "You selected r: Refreshing the filelist."; start ;;
        "ra") echo "You selected ra: Reencode audio."; reencode_audio ;;
        "q") echo "Exiting."; exit 0 ;;
        *) echo "Invalid key. Please enter a valid option." ;;
    esac
}

ask_for_key() {
    print_main_menu
    print_media_table_header
    load_media_arrays
    print_media_table_rows

    echo
    print_screen_separator
    echo
    echo

    read -p "Enter your choice: " key
    dispatch_main_key
}

read_valid_image_file() {
    while true; do
        echo -e "Enter the full ${colorYellow}image${colorReset} file name (with extension. TAB key completes the filename):" >&2
        read -e image_file

        if [[ ! -f "$image_file" ]]; then
            echo "The image file does not exist." >&2
            continue
        fi

        # Check if valid image extension (case insensitive)
        ext="${image_file##*.}"
        shopt -s nocasematch
        valid=0
        for x in jpg jpeg png gif bmp tiff tif; do
            if [[ "$ext" == "$x" ]]; then
                valid=1
                break
            fi
        done
        shopt -u nocasematch

        if [[ $valid -eq 0 ]]; then
            echo -e "The file is ${colorRed}not a valid image${colorReset} file." >&2
            continue
        fi
        printf "%s" "$image_file"
        return 0
    done
}

read_valid_audio_file() {
    while true; do
        echo -e "Enter the full ${colorGreen}audio${colorReset} file name (with extension):" >&2
        read -e audio_file

        if [[ ! -f "$audio_file" ]]; then
            echo "The audio file does not exist." >&2
            continue
        fi

        # Check if valid audio extension (case insensitive)
        ext="${audio_file##*.}"
        shopt -s nocasematch
        valid=0
        for x in mp3 wav wma aac flac ogg m4a; do
            if [[ "$ext" == "$x" ]]; then
                valid=1
                break
            fi
        done
        shopt -u nocasematch

        if [[ $valid -eq 0 ]]; then
            echo -e "The file is ${colorRed}not a valid audio${colorReset} file." >&2
            continue
        fi
        printf "%s" "$audio_file"
        return 0
    done
}

read_output_video_filename() {
    local output_file
    echo -e "Enter the ${colorCyan}output video${colorReset} file name (if no extension present, default is ${colorCyan}mp4${colorReset}):" >&2
    read output_file

    [[ "$output_file" != *.* ]] && output_file="${output_file}.mp4"
    printf "%s" "$output_file"
}

probe_image_dimensions() {
    local image_file="$1"
    local width height

    width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of default=noprint_wrappers=1:nokey=1 "$image_file")
    height=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of default=noprint_wrappers=1:nokey=1 "$image_file")

    if [[ -z "$width" ]]; then
        echo "Failed to get the image width."
        read -p "Press enter to continue..."
        return 1
    fi
    if [[ -z "$height" ]]; then
        echo "Failed to get the image height."
        read -p "Press enter to continue..."
        return 1
    fi

    echo "$width $height"
}

crop_image_if_needed() {
    local image_file="$1"
    local width="$2"
    local height="$3"
    local width_result height_result crop_needed
    local filepath filename extension cropped_image

    echo "Width: $width"
    echo "Height: $height"

    width_result=$((width % 2))
    height_result=$((height % 2))
    crop_needed=0

    if [[ $width_result -ne 0 ]]; then
        echo "Width is not divisible by 2"
        crop_needed=1
    fi
    if [[ $height_result -ne 0 ]]; then
        echo "Height is not divisible by 2"
        crop_needed=1
    fi

    [[ $crop_needed -eq 0 ]] && return 0

    echo "Cropping 1 pixel from the width or height to make it divisible by 2..."
    filepath=$(dirname "$image_file")
    filename=$(basename "$image_file" | cut -d. -f1)
    extension=".${image_file##*.}"
    cropped_image="${filepath}/${filename}_cropped${extension}"

    echo "Input file: \"$image_file\""
    echo "Output file: \"$cropped_image\""
    ffmpeg -i "$image_file" -vf "crop=iw-mod(iw\,2):ih-mod(ih\,2)" "$cropped_image"

    if [[ -f "$cropped_image" ]]; then
        echo "Image cropped successfully."
        echo "Overwriting the original image with the cropped image."
        mv "$cropped_image" "$image_file"
        return 0
    fi

    echo "Failed to crop the image. Check the command and file formats."
    read -p "Press enter to continue..."
    return 1
}

run_image_audio_render() {
    local image_file="$1"
    local audio_file="$2"
    local output_file="$3"

    echo "Input image file: \"$image_file\""
    echo "Audio file: \"$audio_file\""
    echo "Output video file: \"$output_file\""

    case "$key" in
        "t") echo "Key is 't'"; echo "Processing with first 10 seconds of audio..."; ffmpeg -loop 1 -i "$image_file" -i "$audio_file" -c:v libx264 -tune stillimage -preset ultrafast -b:v 500k -af "loudnorm=I=-16:TP=-1.5:LRA=11" -shortest -r 1 -t 10 "$output_file" ;;
        "a") echo "Key is 'a'"; echo "Processing with full \"normalize\" audio..."; ffmpeg -loop 1 -i "$image_file" -i "$audio_file" -c:v libx264 -tune stillimage -preset ultrafast -b:v 500k -af "loudnorm=I=-16:TP=-1.5:LRA=11" -shortest -r 1 "$output_file" ;;
        "af") echo "Key is 'af'"; echo "Processing with full \"copy\" audio..."; ffmpeg -loop 1 -i "$image_file" -i "$audio_file" -c:v libx264 -tune stillimage -preset ultrafast -b:v 500k -c:a libmp3lame -shortest -r 1 "$output_file" ;;
    esac

    prompt_restart
}

test_or_all() {
    local image_file audio_file output_file width height

    image_file="$(read_valid_image_file)"
    audio_file="$(read_valid_audio_file)"
    output_file="$(read_output_video_filename)"
    echo

    [[ ! -f "$audio_file" ]] && echo "The audio file does not exist." && return 1
    read -r width height <<< "$(probe_image_dimensions "$image_file")" || return 1
    crop_image_if_needed "$image_file" "$width" "$height" || return 1
    run_image_audio_render "$image_file" "$audio_file" "$output_file"
}


merge_files() {
    file="list.txt"

    if [[ -f "$file" ]]; then
        line_count=$(wc -l < "$file")
        if [[ $line_count -eq 0 ]]; then
            echo "The file \"$file\" is empty."
        else
            echo "The file \"$file\" has $line_count lines."
        fi

        # Check file format
        echo
        echo "Checking file list.txt"
        error_found=false

        while IFS= read -r line; do
            if [[ $line =~ ^file\ \'.*\.mp3\'$ ]]; then
                echo -e "${colorGreen}OK${colorReset} : $line"
            else
                echo -e "${colorRed}ERROR${colorReset}: $line"
                error_found=true
            fi
        done < "$file"

        echo

        if [[ "$error_found" == "true" ]]; then
            echo -e "${colorRed}Some lines did not match the expected format.${colorReset}"
            read -p "Press enter to continue..."
            return
        else
            echo -e "${colorGreen}All lines match the expected format.${colorReset}"

            while true; do
                read -p "To merge existing, press 'm'. To edit list.txt file, press 'e': " keys
                case "$keys" in
                    "e") prepare_merge_file; break ;;
                    "m") merge_file_execute; break ;;
                esac
            done
        fi
    else
        echo -e "${colorRed}The file \"$file\" does not exist.${colorReset}"
        read -p "To continue and create file with filenames press 'c'. Press 'q' to quit: " keys
        case "$keys" in
            "q") echo "exiting"; return 0 ;;
            "c") prepare_merge_file ;;
        esac
    fi
}

prepare_merge_file() {
    read -p "How many media files do you want to merge? (Enter number or 'q' to quit): " input_count

    if [[ "$input_count" == "q" ]]; then
        echo "Exiting."
        return 0
    fi

    counter=1

    # Remove existing file
    [[ -f "$file" ]] && rm "$file"

    # Collect inputs from user
    while [[ $counter -le $input_count ]]; do
        while true; do
            read -e -p "Enter input $counter: " user_input
            if [[ -f "$user_input" ]]; then
                echo "file '$user_input'" >> "$file"
                break
            else
                echo -e "File \"$user_input\" ${colorRed}does not exist${colorReset}. Please enter a valid filename."
            fi
        done
        ((counter++))
    done

    echo "All media filenames have been saved successfully to list.txt"
    merge_file_execute
}

merge_file_execute() {
    read -e -p "Enter output filename: " output_file
    if [[ "$output_file" != *.* ]]; then
        output_file="${output_file}.mp4"
    fi

    ffmpeg -f concat -safe 0 -i list.txt -c copy "$output_file"
    prompt_restart
}

normalize_audio() {
    while true; do
        echo -e "Enter the input filename (with extension):"
        read -e input_file

        if [[ ! -f "$input_file" ]]; then
            echo "The media file does not exist."
            continue
        fi

        # Check if valid media extension
        if [[ "$input_file" =~ \.(mp3|wav|wma|aac|flac|ogg|m4a|mp4|mkv|avi|mov|wmv|flv|m4v)$ ]]; then
            break
        else
            echo -e "The file is ${colorRed}not a valid media${colorReset} file."
        fi
    done

    name="${input_file%.*}"
    ffmpeg -i "$input_file" -af "loudnorm=I=-16:TP=-1.5:LRA=11" -c:a libmp3lame -b:a 128k "${name}_norm.mp3"
    prompt_restart
}

read_timecode_or_quit() {
    local prompt="$1"
    local time parsed

    while true; do
        echo "$prompt" >&2
        read time

        if [[ "$time" == "q" ]]; then
            echo "Exiting" >&2
            return 2
        fi

        parsed=$(parse_timecode_hhmmss "$time")
        if [[ $? -eq 0 ]]; then
            printf "%s" "$parsed"
            return 0
        fi

        echo -e "${colorRed}Not proper timecode${colorReset}" >&2
    done
}

detect_media_type() {
    local input_file="$1"
    if [[ "$input_file" =~ \.(mp4|mkv|avi|mov|wmv|flv|m4v)$ ]]; then
        printf "video"
    else
        printf "audio"
    fi
}

extract_one_portion() {
    local input_file="$1"
    local beginning_time="$2"
    local end_time="$3"
    local type="$4"
    local name="$5"
    local ext="$6"
    local counter="$7"

    echo "Beginning time: $beginning_time"
    echo "End time: $end_time"
    echo "Type: $type"

    if [[ "$type" == "audio" ]]; then
        ffmpeg -i "$input_file" -ss "$beginning_time" -to "$end_time" -c copy "${name}_portion${counter}.${ext}"
    else
        ffmpeg -i "$input_file" -ss "$beginning_time" -to "$end_time" -c:v libx264 -preset ultrafast -c:a copy "${name}_portion${counter}.${ext}"
    fi
}

prompt_extract_next_action() {
    local next_key
    echo >&2
    echo "Press 'e' to extract another portion or" >&2
    echo "Enter to return to beginning or" >&2
    echo "'q' to quit:" >&2
    read next_key
    printf "%s" "$next_key"
}

extract_portion() {
    local input_file name ext type counter
    local beginning_time end_time next_key

    while true; do
        echo -e "Enter the input filename (with extension):"
        read -e input_file

        if [[ ! -f "$input_file" ]]; then
            echo "The media file does not exist."
            continue
        fi

        # Check if valid media extension
        if [[ "$input_file" =~ \.(mp3|wav|wma|aac|flac|ogg|m4a|mp4|mkv|avi|mov|wmv|flv|m4v)$ ]]; then
            break
        else
            echo -e "The file is ${colorRed}not a valid media${colorReset} file."
        fi
    done

    name="${input_file%.*}"
    ext="${input_file##*.}"
    type="$(detect_media_type "$input_file")"
    counter=1

    while true; do
        beginning_time="$(read_timecode_or_quit "Enter the beginning timecode (format: HH:MM:SS or MM:SS):")"
        [[ $? -eq 2 ]] && return 0
        end_time="$(read_timecode_or_quit "Enter the end timecode (format: HH:MM:SS or MM:SS):")"
        [[ $? -eq 2 ]] && return 0

        extract_one_portion "$input_file" "$beginning_time" "$end_time" "$type" "$name" "$ext" "$counter"
        next_key="$(prompt_extract_next_action)"

        case "$next_key" in
            "q") echo "Exiting"; return 0 ;;
            "e") ((counter++)); continue ;;
            *) start ;;
        esac
    done
}

reencode_audio() {
    while true; do
        echo -e "Enter the input filename (with extension):"
        read -e input_file

        if [[ ! -f "$input_file" ]]; then
            echo "The media file does not exist."
            continue
        fi

        # Check if valid audio extension
        if [[ "$input_file" =~ \.(mp3|wav|wma|aac|flac|ogg|m4a)$ ]]; then
            break
        else
            echo -e "The file is ${colorRed}not a valid audio${colorReset} file."
        fi
    done

    name="${input_file%.*}"
    ffmpeg -i "$input_file" -c:a libmp3lame -b:a 128k "${name}_reencoded.mp3"
    prompt_restart
}

resolve_trim_media_type() {
    local ext="$1"

    shopt -s nocasematch
    if [[ "$ext" =~ ^(mp4|mkv|avi|mov|wmv|flv|m4v)$ ]]; then
        shopt -u nocasematch
        printf "video"
        return 0
    fi
    if [[ "$ext" =~ ^(mp3|wav|flac|aac|ogg|m4a|wma)$ ]]; then
        shopt -u nocasematch
        printf "audio"
        return 0
    fi
    shopt -u nocasematch
    return 1
}

run_trim_end() {
    local input_file="$1" name="$2" ext="$3" time_formatted="$4"
    echo "You selected trim end"
    ffmpeg -i "$input_file" -t "$time_formatted" -c copy "${name}_trimmed_end.${ext}"
}

run_trim_beginning() {
    local input_file="$1" name="$2" ext="$3" type="$4" time_formatted="$5"
    echo "You selected trim beginning"
    if [[ "$type" == "video" ]]; then
        ffmpeg -i "$input_file" -ss "$time_formatted" -c:v libx264 -preset ultrafast -c:a copy "${name}_trimmed_beginning.${ext}"
    else
        ffmpeg -i "$input_file" -ss "$time_formatted" -c copy "${name}_trimmed_beginning.${ext}"
    fi
}

run_split() {
    local input_file="$1" name="$2" ext="$3" type="$4" time_formatted="$5"
    echo "You selected split"
    ffmpeg -i "$input_file" -t "$time_formatted" -c copy "${name}_A.${ext}"
    if [[ "$type" == "video" ]]; then
        ffmpeg -i "$input_file" -ss "$time_formatted" -c:v libx264 -preset ultrafast -c:a copy "${name}_B.${ext}"
    else
        ffmpeg -i "$input_file" -ss "$time_formatted" -c copy "${name}_B.${ext}"
    fi
}

run_split_swap() {
    local input_file="$1" name="$2" ext="$3" type="$4" time_formatted="$5"
    local output_file_a="${name}_A.${ext}" output_file_b="${name}_B.${ext}" swapped_file="${name}_swapped.${ext}"

    echo "You selected split and swap"
    if [[ "$type" == "audio" ]]; then
        ffmpeg -i "$input_file" -t "$time_formatted" -c copy "$output_file_a"
        ffmpeg -i "$input_file" -ss "$time_formatted" -c copy "$output_file_b"
        ffmpeg -i "concat:$output_file_b|$output_file_a" -c copy "$swapped_file"
    else
        ffmpeg -i "$input_file" -t "$time_formatted" -c:v libx264 -preset ultrafast -c:a copy "$output_file_a"
        ffmpeg -i "$input_file" -ss "$time_formatted" -c:v libx264 -preset ultrafast -c:a copy "$output_file_b"
        ffmpeg -i "$output_file_b" -i "$output_file_a" -filter_complex "[0:v:0][0:a:0][1:v:0][1:a:0]concat=n=2:v=1:a=1[outv][outa]" -map "[outv]" -map "[outa]" "$swapped_file"
    fi
    rm "$output_file_a" "$output_file_b"
    echo "Split and swap successful. $swapped_file created."
}

execute_trim_operation() {
    local input_file="$1" name="$2" ext="$3" type="$4" time_formatted="$5"
    case "$key" in
        te) run_trim_end "$input_file" "$name" "$ext" "$time_formatted" ;;
        tb) run_trim_beginning "$input_file" "$name" "$ext" "$type" "$time_formatted" ;;
        s) run_split "$input_file" "$name" "$ext" "$type" "$time_formatted" ;;
        ss) run_split_swap "$input_file" "$name" "$ext" "$type" "$time_formatted" ;;
        *) echo "Invalid option for trim/split/swap operation."; return 1 ;;
    esac
}

trimSplitSwapFile() {
    local input_file filename ext name type time time_formatted
    echo
    echo "Enter the input filename (with extension):"
    read -e input_file

    # Check if file exists
    if [[ ! -f "$input_file" ]]; then
        echo "The input file does not exist."
        return 1
    fi

    # Extract base name and extension
    filename=$(basename -- "$input_file")
    ext="${filename##*.}"
    name="${filename%.*}"

    type="$(resolve_trim_media_type "$ext")"
    if [[ $? -ne 0 ]]; then
        echo "Unsupported file type: $ext"
        return 1
    fi

    echo "Media type detected: $type"

    while true; do
        echo "Enter the timecode (format: HH:MM:SS or MM:SS) or 'q' to quit:"
        read time

        if [[ "$time" == "q" ]]; then
            echo "Exiting"
            return 1
        fi

        # Parse timecode - split by colons
        time_formatted=$(parse_timecode_hhmmss "$time")
        if [[ $? -ne 0 ]]; then
            echo -e "${colorRed}Not proper timecode${colorReset}"
            continue
        fi

        echo "Formatted time: $time_formatted"

        execute_trim_operation "$input_file" "$name" "$ext" "$type" "$time_formatted" || return 1

        break
    done

    prompt_restart
}


prompt_restart() {
    [[ "$NON_INTERACTIVE" -eq 1 ]] && return 0

    echo
    echo
    while true; do
        read -p "Do you want to restart (r) again or quit (q)? Enter your choice: " choice
        case "$choice" in
            [Rr]) start ;;
            [Qq]) exit 0 ;;
            *) echo "Invalid choice! Please enter 'r' or 'q'." ;;
        esac
    done
}

print_usage() {
    cat <<'EOF'
Usage:
  converter.sh
  converter.sh <key> [options]

Keys and options:
  t|a|af  --image <file> --audio <file> [--output <file>]
  te|tb|s|ss  --input <file> --time <HH:MM:SS|MM:SS>
  na|ra  --input <file>
  ex  --input <file> --start <HH:MM:SS|MM:SS> --end <HH:MM:SS|MM:SS>
  m  [--list <file>] --output <file>
EOF
}

ensure_mp4_extension() {
    local output_file="$1"
    [[ "$output_file" != *.* ]] && output_file="${output_file}.mp4"
    printf "%s" "$output_file"
}

run_cli_image_audio() {
    local cli_key="$1" image_file="$2" audio_file="$3" output_file="$4"
    local width height

    [[ ! -f "$image_file" ]] && echo "The image file does not exist." && return 1
    [[ ! -f "$audio_file" ]] && echo "The audio file does not exist." && return 1
    output_file="$(ensure_mp4_extension "$output_file")"

    read -r width height <<< "$(probe_image_dimensions "$image_file")" || return 1
    crop_image_if_needed "$image_file" "$width" "$height" || return 1
    key="$cli_key"
    run_image_audio_render "$image_file" "$audio_file" "$output_file"
}

run_cli_trim() {
    local cli_key="$1" input_file="$2" raw_time="$3"
    local filename ext name type time_formatted

    [[ ! -f "$input_file" ]] && echo "The input file does not exist." && return 1
    time_formatted="$(parse_timecode_hhmmss "$raw_time")" || { echo -e "${colorRed}Not proper timecode${colorReset}"; return 1; }

    filename=$(basename -- "$input_file")
    ext="${filename##*.}"
    name="${filename%.*}"
    type="$(resolve_trim_media_type "$ext")" || { echo "Unsupported file type: $ext"; return 1; }
    key="$cli_key"
    execute_trim_operation "$input_file" "$name" "$ext" "$type" "$time_formatted"
}

run_cli_extract() {
    local input_file="$1" raw_start="$2" raw_end="$3"
    local name ext type start_time end_time

    [[ ! -f "$input_file" ]] && echo "The media file does not exist." && return 1
    start_time="$(parse_timecode_hhmmss "$raw_start")" || { echo -e "${colorRed}Not proper timecode${colorReset}"; return 1; }
    end_time="$(parse_timecode_hhmmss "$raw_end")" || { echo -e "${colorRed}Not proper timecode${colorReset}"; return 1; }

    name="${input_file%.*}"
    ext="${input_file##*.}"
    type="$(detect_media_type "$input_file")"
    extract_one_portion "$input_file" "$start_time" "$end_time" "$type" "$name" "$ext" "1"
}

run_cli_merge() {
    local list_file="$1" output_file="$2"
    [[ ! -f "$list_file" ]] && echo "The file \"$list_file\" does not exist." && return 1
    ffmpeg -f concat -safe 0 -i "$list_file" -c copy "$output_file"
}

run_cli_key() {
    local cli_key="$1"
    local image_file="" audio_file="" output_file="" input_file="" raw_time="" start_time="" end_time="" list_file="list.txt"

    shift
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --image) image_file="$2"; shift 2 ;;
            --audio) audio_file="$2"; shift 2 ;;
            --output) output_file="$2"; shift 2 ;;
            --input) input_file="$2"; shift 2 ;;
            --time) raw_time="$2"; shift 2 ;;
            --start) start_time="$2"; shift 2 ;;
            --end) end_time="$2"; shift 2 ;;
            --list) list_file="$2"; shift 2 ;;
            -h|--help) print_usage; return 0 ;;
            *) echo "Unknown option: $1"; print_usage; return 1 ;;
        esac
    done

    case "$cli_key" in
        t|a|af)
            [[ -z "$image_file" || -z "$audio_file" ]] && print_usage && return 1
            [[ -z "$output_file" ]] && output_file="output.mp4"
            run_cli_image_audio "$cli_key" "$image_file" "$audio_file" "$output_file"
            ;;
        te|tb|s|ss)
            [[ -z "$input_file" || -z "$raw_time" ]] && print_usage && return 1
            run_cli_trim "$cli_key" "$input_file" "$raw_time"
            ;;
        na)
            [[ -z "$input_file" ]] && print_usage && return 1
            name="${input_file%.*}"
            ffmpeg -i "$input_file" -af "loudnorm=I=-16:TP=-1.5:LRA=11" -c:a libmp3lame -b:a 128k "${name}_norm.mp3"
            ;;
        ra)
            [[ -z "$input_file" ]] && print_usage && return 1
            name="${input_file%.*}"
            ffmpeg -i "$input_file" -c:a libmp3lame -b:a 128k "${name}_reencoded.mp3"
            ;;
        ex)
            [[ -z "$input_file" || -z "$start_time" || -z "$end_time" ]] && print_usage && return 1
            run_cli_extract "$input_file" "$start_time" "$end_time"
            ;;
        m)
            [[ -z "$output_file" ]] && print_usage && return 1
            run_cli_merge "$list_file" "$output_file"
            ;;
        *)
            echo "Unknown key: $cli_key"
            print_usage
            return 1
            ;;
    esac
}

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo -e "${colorRed}ffmpeg is not installed or not in PATH${colorReset}"
    echo "Please install ffmpeg first:"
    echo "Ubuntu/Debian: sudo apt install ffmpeg"
    echo "CentOS/RHEL: sudo yum install ffmpeg"
    echo "Arch: sudo pacman -S ffmpeg"
    exit 1
fi

if ! command -v ffprobe &> /dev/null; then
    echo -e "${colorRed}ffprobe is not installed or not in PATH${colorReset}"
    echo "Please install ffmpeg/ffprobe first:"
    echo "Ubuntu/Debian: sudo apt install ffmpeg"
    echo "CentOS/RHEL: sudo yum install ffmpeg"
    echo "Arch: sudo pacman -S ffmpeg"
    exit 1
fi

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    if [[ $# -gt 0 ]]; then
        if [[ "$1" == "-h" || "$1" == "--help" ]]; then
            print_usage
            exit 0
        fi
        NON_INTERACTIVE=1
        run_cli_key "$@"
    else
        # Start the program
        start
    fi
fi
