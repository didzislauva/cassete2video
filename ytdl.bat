@echo off
:: Batch script to download the best quality MP4 from a YouTube link using yt-dlp
set /p url="Enter YouTube URL: "

:: Command to download the best quality video in MP4 format
yt-dlp.exe -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]" -o "%(title)s.%(ext)s" %url%

echo Download complete.
pause