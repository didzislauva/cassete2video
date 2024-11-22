
# Media Processing Automation Tool

A versatile command-line tool for managing and processing media files using **FFmpeg**, designed primarily for digitizing old cassette recordings and preparing content for platforms like YouTube. The script offers a user-friendly menu-driven interface to perform various audio and video operations efficiently.

---

## Features

- **File Management**: Automatically lists and categorizes images, audio, and video files in the current directory.
- **Media Processing**:
  - **Trimming & Splitting**:
    - Trim files from the beginning or end.
    - Split files into segments based on timecodes.
  - **Merging**: Combine multiple media files into a single output.
  - **Re-encoding**: Convert audio files to MP3 with optional normalization.
  - **Extracting Portions**: Extract specific sections from audio or video files.
  - **Audio Normalization**: Ensure consistent playback levels across files.
  - **Video Creation**: Combine images and audio into videos.
- **Compatibility**:
  - Crops images dynamically if dimensions are not divisible by 2 (required for FFmpeg).
  - Supports a wide range of file formats:
    - **Images**: `.jpg`, `.jpeg`, `.png`, `.gif`, etc.
    - **Audio**: `.mp3`, `.wav`, `.aac`, `.flac`, etc.
    - **Video**: `.mp4`, `.avi`, `.mkv`, `.mov`, etc.
- **Error Handling**:
  - Validates file paths, extensions, and timecodes.
  - Provides clear feedback and prompts for invalid inputs.
- **Customization**:
  - Specify output file names.
  - Append missing file extensions dynamically.

---

## Requirements

- **Windows**: Supports Windows 7 and above (with ANSI color detection for enhanced visuals).
- **FFmpeg**: Must be installed and accessible via the command line.
- **Dependencies**: No additional dependencies.

---

## How It Works

1. Run the script in the directory containing your media files.
2. Follow the menu prompts to:
   - Trim, split, or merge media files.
   - Normalize audio.
   - Create videos by combining images and audio.
   - Re-encode files for improved compatibility.
3. Save output files for further use or upload to platforms like YouTube.

---

## Usage

1. Clone this repository or download the script.
2. Ensure FFmpeg is installed and available in your PATH.
3. Run the script in the command line:
   ```cmd
   script_name.bat
   ```
4. Follow the on-screen instructions.

---

## Menu Options

- `t`: Create a video from the first 10 seconds of audio with normalization.
- `a`: Convert a full MP3 to video with normalization.
- `af`: Convert a full MP3 to video without normalization.
- `s`: Split media files at a specified time.
- `te` / `tb`: Trim media files from the end or beginning.
- `ss`: Split and swap portions of media files.
- `m`: Merge files listed in `list.txt`.
- `na`: Normalize audio streams.
- `ex`: Extract portions of media files.
- `ra`: Re-encode audio files.
- `r`: Refresh the file list.
- `q`: Quit the program.

---

## Example Workflow

1. **Digitizing Cassette Recordings**:
   - Record audio from cassettes and save as MP3 files.
   - Normalize audio to ensure consistent sound levels.
   - Combine MP3 audio with an image to create a video for YouTube.

2. **Editing and Trimming**:
   - Split audio into segments for easier editing.
   - Trim unwanted sections from the start or end of recordings.

3. **File Merging**:
   - Combine multiple tracks or videos into a single cohesive output.

---

## Contributing

Contributions are welcome! Feel free to submit issues or pull requests to improve the script.

---

## License

This project is licensed under the [MIT License](LICENSE).
