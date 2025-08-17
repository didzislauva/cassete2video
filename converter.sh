#!/bin/bash

# Enable extended globbing for pattern matching
shopt -s nullglob

# Set terminal size (optional, works if terminal supports it)
printf '\e[8;40;88t'

# Color definitions for ANSI escape sequences
colorYellow='\e[93m'
colorGreen='\e[92m'
colorCyan='\e[96m'
colorReset='\e[0m'
colorRed='\e[91m'

# Maximum length for filenames in each column
max_length=25

start() {
    clear

    while true; do
        ask_for_key
    done
}

ask_for_key() {
    echo "======================================================================================="
    echo "Program available media work with didzis@lauvadidzis.com"
    echo "======================================================================================="
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

    # Create headers
    echo "======================================================================================="
    echo -e "File list for available media work with ${colorGreen}ffmpeg${colorReset}"
    echo
    echo -e "${colorYellow}Images:${colorReset} ${colorGreen}Audio:${colorReset} ${colorCyan}Video:${colorReset}"
    echo "_______________________________________________________________________________________"
    echo

    # Arrays to store filenames
    img_files=(*.jpg *.jpeg *.png *.gif *.bmp *.tiff *.tif)
    aud_files=(*.mp3 *.wav *.wma *.aac *.flac *.ogg *.m4a)
    vid_files=(*.mp4 *.avi *.mkv *.mov *.wmv *.flv *.mpeg *.mpg *.webm)

    # Find the max count to determine loop iterations
    img_count=${#img_files[@]}
    aud_count=${#aud_files[@]}
    vid_count=${#vid_files[@]}

    max_count=$img_count
    [[ $aud_count -gt $max_count ]] && max_count=$aud_count
    [[ $vid_count -gt $max_count ]] && max_count=$vid_count

    # Print the table
    for ((i=0; i<max_count; i++)); do
        img_display=""
        aud_display=""
        vid_display=""

        # Handle image files
        if [[ $i -lt $img_count ]]; then
            img_display="${img_files[$i]}"
            if [[ ${#img_display} -gt $max_length ]]; then
                img_display="${img_display:0:$max_length}..."
            fi
        fi

        # Handle audio files
        if [[ $i -lt $aud_count ]]; then
            aud_display="${aud_files[$i]}"
            if [[ ${#aud_display} -gt $max_length ]]; then
                aud_display="${aud_display:0:$max_length}..."
            fi
        fi

        # Handle video files
        if [[ $i -lt $vid_count ]]; then
            vid_display="${vid_files[$i]}"
            if [[ ${#vid_display} -gt $max_length ]]; then
                vid_display="${vid_display:0:$max_length}..."
            fi
        fi

        # Print the row with proper padding
        printf "%-${max_length}s %-${max_length}s %-${max_length}s\n" "$img_display" "$aud_display" "$vid_display"
    done

    echo
    echo "======================================================================================="
    echo
    echo

    read -p "Enter your choice: " key

    case "$key" in
        "t")
            echo "You selected t: First 10 seconds."
            test_or_all
            ;;
        "a")
            echo "You selected a: Full MP3. With sound normalization filter."
            test_or_all
            ;;
        "af")
            echo "You selected af: Fast Full MP3. Without sound normalization."
            test_or_all
            ;;
        "s")
            echo "You selected s: Split file."
            trimSplitSwapFile
            ;;
        "m")
            echo "You selected m: Merge files from list."
            merge_files
            ;;
        "te")
            echo "You selected te: Trim end in file."
            trimSplitSwapFile
            ;;
        "tb")
            echo "You selected tb: Trim beginning in file."
            trimSplitSwapFile
            ;;
        "ss")
            echo "You selected ss: Split, swap and merge."
            trimSplitSwapFile
            ;;
        "na")
            echo "You selected na: Normalize audio."
            normalize_audio
            ;;
        "ex")
            echo "You selected ex: Extracting a portion."
            extract_portion
            ;;
        "r")
            echo "You selected r: Refreshing the filelist."
            start
            ;;
        "ra")
            echo "You selected ra: Reencode audio."
            reencode_audio
            ;;
        "q")
            echo "Exiting."
            exit 0
            ;;
        *)
            echo "Invalid key. Please enter a valid option."
            ;;
    esac
}

test_or_all() {
    # Get image file
    while true; do
        echo -e "Enter the full ${colorYellow}image${colorReset} file name (with extension. TAB key completes the filename):"
        read -e image_file

        if [[ ! -f "$image_file" ]]; then
            echo "The image file does not exist."
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
            echo -e "The file is ${colorRed}not a valid image${colorReset} file."
            continue
        fi
        break
    done

    # Get audio file
    while true; do
        echo -e "Enter the full ${colorGreen}audio${colorReset} file name (with extension):"
        read -e audio_file

        if [[ ! -f "$audio_file" ]]; then
            echo "The audio file does not exist."
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
            echo -e "The file is ${colorRed}not a valid audio${colorReset} file."
            continue
        fi
        break
    done

    # Get output file name
    echo -e "Enter the ${colorCyan}output video${colorReset} file name (if no extension present, default is ${colorCyan}mp4${colorReset}):"
    read output_file

    # Add .mp4 extension if none provided
    if [[ "$output_file" != *.* ]]; then
        output_file="${output_file}.mp4"
    fi

    echo

    # Double check if audio file exists (matching original)
    if [[ ! -f "$audio_file" ]]; then
        echo "The audio file does not exist."
        exit 1
    fi

    # Get image dimensions using ffprobe
    width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of default=noprint_wrappers=1:nokey=1 "$image_file")
    height=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of default=noprint_wrappers=1:nokey=1 "$image_file")

    # Check if ffprobe was successful
    if [[ -z "$width" ]]; then
        echo "Failed to get the image width."
        read -p "Press enter to continue..."
        exit 1
    fi
    if [[ -z "$height" ]]; then
        echo "Failed to get the image height."
        read -p "Press enter to continue..."
        exit 1
    fi

    # Display the width and height
    echo "Width: $width"
    echo "Height: $height"

    # Check if width and height are divisible by 2
    width_result=$((width % 2))
    height_result=$((height % 2))

    # Initialize cropping flag
    crop_needed=0
    if [[ $width_result -ne 0 ]]; then
        echo "Width is not divisible by 2"
        crop_needed=1
    fi
    if [[ $height_result -ne 0 ]]; then
        echo "Height is not divisible by 2"
        crop_needed=1
    fi

    if [[ $crop_needed -ne 0 ]]; then
        echo "Cropping 1 pixel from the width or height to make it divisible by 2..."

        # Extract directory, filename and extension
        filepath=$(dirname "$image_file")
        filename=$(basename "$image_file" | cut -d. -f1)
        extension=".${image_file##*.}"

        # Define a temporary output file name in the same directory as the input file
        cropped_image="${filepath}/${filename}_cropped${extension}"

        # Display the file names for debugging
        echo "Input file: \"$image_file\""
        echo "Output file: \"$cropped_image\""

        # Crop the image to remove 1 pixel if needed
        ffmpeg -i "$image_file" -vf "crop=iw-mod(iw\,2):ih-mod(ih\,2)" "$cropped_image"

        # Check if cropping was successful
        if [[ -f "$cropped_image" ]]; then
            echo "Image cropped successfully."
            echo "Overwriting the original image with the cropped image."
            mv "$cropped_image" "$image_file"
        else
            echo "Failed to crop the image. Check the command and file formats."
            read -p "Press enter to continue..."
            exit 1
        fi
    fi

    # Debugging output
    echo "Input image file: \"$image_file\""
    echo "Audio file: \"$audio_file\""
    echo "Output video file: \"$output_file\""

    # Process based on the key
    if [[ "$key" == "t" ]]; then
        echo "Key is 't'"
        echo "Processing with first 10 seconds of audio..."
        ffmpeg -loop 1 -i "$image_file" -i "$audio_file" -c:v libx264 -tune stillimage -preset ultrafast -b:v 500k -af "loudnorm=I=-16:TP=-1.5:LRA=11" -shortest -r 1 -t 10 "$output_file"
        prompt_restart
    elif [[ "$key" == "a" ]]; then
        echo "Key is 'a'"
        echo "Processing with full \"normalize\" audio..."
        ffmpeg -loop 1 -i "$image_file" -i "$audio_file" -c:v libx264 -tune stillimage -preset ultrafast -b:v 500k -af "loudnorm=I=-16:TP=-1.5:LRA=11" -shortest -r 1 "$output_file"
        prompt_restart
    elif [[ "$key" == "af" ]]; then
        echo "Key is 'af'"
        echo "Processing with full \"copy\" audio..."
        ffmpeg -loop 1 -i "$image_file" -i "$audio_file" -c:v libx264 -tune stillimage -preset ultrafast -b:v 500k -c:a libmp3lame -shortest -r 1 "$output_file"
        prompt_restart
    fi
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
            "q") echo "exiting"; exit 0 ;;
            "c") prepare_merge_file ;;
        esac
    fi
}

prepare_merge_file() {
    read -p "How many media files do you want to merge? (Enter number or 'q' to quit): " input_count

    if [[ "$input_count" == "q" ]]; then
        echo "Exiting."
        exit 0
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

extract_portion() {
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

    # Determine if it's video or audio
    if [[ "$input_file" =~ \.(mp4|mkv|avi|mov|wmv|flv|m4v)$ ]]; then
        type="video"
    else
        type="audio"
    fi

    counter=1

    while true; do
        # Get beginning time
        while true; do
            echo "Enter the beginning timecode (format: HH:MM:SS or MM:SS):"
            read time

            if [[ "$time" == "q" ]]; then
                echo "Exiting"
                exit 0
            fi

            # Validate and format timecode
            if [[ $time =~ ^[0-9]{1,2}:[0-9]{1,2}$ ]]; then
                beginning_time="00:$time"
                break
            elif [[ $time =~ ^[0-9]{1,2}:[0-9]{1,2}:[0-9]{1,2}$ ]]; then
                beginning_time="$time"
                break
            else
                echo -e "${colorRed}Not proper timecode${colorReset}"
            fi
        done

        # Get end time
        while true; do
            echo "Enter the end timecode (format: HH:MM:SS or MM:SS):"
            read time

            if [[ "$time" == "q" ]]; then
                echo "Exiting"
                exit 0
            fi

            # Validate and format timecode
            if [[ $time =~ ^[0-9]{1,2}:[0-9]{1,2}$ ]]; then
                end_time="00:$time"
                break
            elif [[ $time =~ ^[0-9]{1,2}:[0-9]{1,2}:[0-9]{1,2}$ ]]; then
                end_time="$time"
                break
            else
                echo -e "${colorRed}Not proper timecode${colorReset}"
            fi
        done

        echo "Beginning time: $beginning_time"
        echo "End time: $end_time"
        echo "Type: $type"

        if [[ "$type" == "audio" ]]; then
            ffmpeg -i "$input_file" -ss "$beginning_time" -to "$end_time" -c copy "${name}_portion${counter}.${ext}"
        else
            ffmpeg -i "$input_file" -ss "$beginning_time" -to "$end_time" -c:v libx264 -preset ultrafast -c:a copy "${name}_portion${counter}.${ext}"
        fi

        echo
        echo "Press 'e' to extract another portion or"
        echo "Enter to return to beginning or"
        echo "'q' to quit:"
        read key

        case "$key" in
            "q") echo "Exiting"; exit 0 ;;
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

trimSplitSwapFile() {
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

    # Determine media type (case insensitive)
    shopt -s nocasematch
    if [[ "$ext" =~ ^(mp4|mkv|avi|mov|wmv|flv|m4v)$ ]]; then
        type="video"
    elif [[ "$ext" =~ ^(mp3|wav|flac|aac|ogg|m4a|wma)$ ]]; then
        type="audio"
    else
        echo "Unsupported file type: $ext"
        return 1
    fi
    shopt -u nocasematch

    echo "Media type detected: $type"

    while true; do
        echo "Enter the timecode (format: HH:MM:SS or MM:SS) or 'q' to quit:"
        read time

        if [[ "$time" == "q" ]]; then
            echo "Exiting"
            return 1
        fi

        # Parse timecode - split by colons
        IFS=':' read -ra time_parts <<< "$time"

        if [[ ${#time_parts[@]} -lt 2 ]]; then
            echo -e "${colorRed}Not proper timecode${colorReset}"
            continue
        fi

        # Determine format and assign values
        if [[ ${#time_parts[@]} -eq 3 ]]; then
            # HH:MM:SS format
            hours="${time_parts[0]}"
            minutes="${time_parts[1]}"
            seconds="${time_parts}"
        else
            # MM:SS format - add 00 hours
            hours="00"
            minutes="${time_parts}"
            seconds="${time_parts[1]}"
        fi

        # Zero pad if needed (ensure two digits)
        hours=$(printf "%02d" $((10#$hours)))
        minutes=$(printf "%02d" $((10#$minutes)))
        seconds=$(printf "%02d" $((10#$seconds)))

        time_formatted="$hours:$minutes:$seconds"
        echo "Formatted time: $time_formatted"

        case "$key" in
            te)  # Trim end - keep from start to specified time
                echo "You selected trim end"
                output_file="${name}_trimmed_end.${ext}"
                ffmpeg -i "$input_file" -t "$time_formatted" -c copy "$output_file"
                ;;

            tb)  # Trim beginning - keep from specified time to end
                echo "You selected trim beginning"
                output_file="${name}_trimmed_beginning.${ext}"
                if [[ "$type" == "video" ]]; then
                    ffmpeg -i "$input_file" -ss "$time_formatted" -c:v libx264 -preset ultrafast -c:a copy "$output_file"
                else
                    ffmpeg -i "$input_file" -ss "$time_formatted" -c copy "$output_file"
                fi
                ;;

            s)   # Split - create two files at specified time
                echo "You selected split"
                output_file_a="${name}_A.${ext}"
                output_file_b="${name}_B.${ext}"

                # First part (start to split time)
                ffmpeg -i "$input_file" -t "$time_formatted" -c copy "$output_file_a"

                # Second part (split time to end)
                if [[ "$type" == "video" ]]; then
                    ffmpeg -i "$input_file" -ss "$time_formatted" -c:v libx264 -preset ultrafast -c:a copy "$output_file_b"
                else
                    ffmpeg -i "$input_file" -ss "$time_formatted" -c copy "$output_file_b"
                fi
                ;;

            ss)  # Split and swap - split then concatenate in reverse order
                echo "You selected split and swap"
                output_file_a="${name}_A.${ext}"
                output_file_b="${name}_B.${ext}"
                swapped_file="${name}_swapped.${ext}"

                if [[ "$type" == "audio" ]]; then
                    # For audio files
                    ffmpeg -i "$input_file" -t "$time_formatted" -c copy "$output_file_a"
                    ffmpeg -i "$input_file" -ss "$time_formatted" -c copy "$output_file_b"
                    # Concatenate B then A (swapped order)
                    ffmpeg -i "concat:$output_file_b|$output_file_a" -c copy "$swapped_file"
                    rm "$output_file_a" "$output_file_b"
                else
                    # For video files
                    ffmpeg -i "$input_file" -t "$time_formatted" -c:v libx264 -preset ultrafast -c:a copy "$output_file_a"
                    ffmpeg -i "$input_file" -ss "$time_formatted" -c:v libx264 -preset ultrafast -c:a copy "$output_file_b"
                    # Concatenate B then A (swapped order) using filter_complex
                    ffmpeg -i "$output_file_b" -i "$output_file_a" -filter_complex "[0:v:0][0:a:0][1:v:0][1:a:0]concat=n=2:v=1:a=1[outv][outa]" \
                        -map "[outv]" -map "[outa]" "$swapped_file"
                    rm "$output_file_a" "$output_file_b"
                fi
                echo "Split and swap successful. $swapped_file created."
                ;;

            *)
                echo "Invalid option for trim/split/swap operation."
                return 1
                ;;
        esac

        break
    done

    prompt_restart
}


prompt_restart() {
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

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo -e "${colorRed}ffmpeg is not installed or not in PATH${colorReset}"
    echo "Please install ffmpeg first:"
    echo "Ubuntu/Debian: sudo apt install ffmpeg"
    echo "CentOS/RHEL: sudo yum install ffmpeg"
    echo "Arch: sudo pacman -S ffmpeg"
    exit 1
fi

# Start the program
start
