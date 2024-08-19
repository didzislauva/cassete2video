@echo off
setlocal enabledelayedexpansion

:: Prompt user for the key (t for last 10 seconds, a for full MP3)
echo Enter the key (t for last 10 seconds, a for full MP3):
set /p key=

:: Debugging output
echo Key entered: "%key%"

:: Prompt user for the image file path
echo Enter the path to the image file:
set /p image_file=

:: Prompt user for the audio file path
echo Enter the path to the audio file:
set /p audio_file=

:: Prompt user for the output video file name
echo Enter the output video file name:
set /p output_file=

:: Check if the image file exists
if not exist "%image_file%" (
    echo The image file does not exist.
    exit /b 1
)

:: Check if the audio file exists
if not exist "%audio_file%" (
    echo The audio file does not exist.
    exit /b 1
)

:: Get the image width and height using ffprobe and store them in separate temporary files
ffprobe -v error -select_streams v:0 -show_entries stream=width -of default=noprint_wrappers=1:nokey=1 "%image_file%" > width.txt
ffprobe -v error -select_streams v:0 -show_entries stream=height -of default=noprint_wrappers=1:nokey=1 "%image_file%" > height.txt

:: Read the width and height from the temporary files
set /p width=<width.txt
set /p height=<height.txt

:: Clean up temporary files
del width.txt
del height.txt

:: Check if ffprobe was successful
if "%width%"=="" (
    echo Failed to get the image width.
    pause
    exit /b 1
)

if "%height%"=="" (
    echo Failed to get the image height.
    pause
    exit /b 1
)

:: Display the width and height
echo Width: %width%
echo Height: %height%

:: Check if width is divisible by 2
set /a width_result=width %% 2

:: Check if height is divisible by 2
set /a height_result=height %% 2

:: Initialize cropping flag
set crop_needed=0

if !width_result! neq 0 (
    echo Width is not divisible by 2
    set /a crop_needed=1
)

if !height_result! neq 0 (
    echo Height is not divisible by 2
    set /a crop_needed=1
)

if !crop_needed! neq 0 (
    echo Cropping 1 pixel from the width or height to make it divisible by 2...

    :: Extract only the filename and extension from the input file
    for %%f in ("%image_file%") do (
        set "filename=%%~nf"
        set "extension=%%~xf"
        set "filepath=%%~dpf"
    )

    :: Define a temporary output file name in the same directory as the input file
    set "cropped_image=!filepath!!filename!_cropped!extension!"

    :: Display the file names for debugging
    echo Input file: "%image_file%"
    echo Output file: "!cropped_image!"

    :: Crop the image to remove 1 pixel if needed
    ffmpeg -i "%image_file%" -vf "crop=iw-mod(iw\,2):ih-mod(ih\,2)" "!cropped_image!"

    :: Check if cropping was successful
    if exist "!cropped_image!" (
        echo Image cropped successfully.
        echo Overwriting the original image with the cropped image.
        move /y "!cropped_image!" "%image_file%"
    ) else (
        echo Failed to crop the image. Check the command and file formats.
        pause
        exit /b 1
    )
)

:: Debugging output
echo Input image file: "%image_file%"
echo Audio file: "%audio_file%"
echo Output video file: "%output_file%"

:: Process based on the key
if /i "%key%"=="t" (
    echo Key is 't'
    echo Processing with last 10 seconds of audio...
    ffmpeg -loop 1 -i "%image_file%" -i "%audio_file%" -c:v libx264 -tune stillimage -preset ultrafast -b:v 500k -c:a copy -shortest -r 1 -t 10 "%output_file%"

) else if /i "%key%"=="a" (
    echo Key is 'a'
    echo Processing with full audio...
    ffmpeg -loop 1 -i "%image_file%" -i "%audio_file%" -c:v libx264 -tune stillimage -preset ultrafast -b:v 500k -c:a copy -shortest -r 1 "%output_file%"

) else (
    echo Invalid key. Please enter 't' for last 10 seconds or 'a' for full MP3.
    exit /b 1
)

endlocal
pause
