@echo off
setlocal enabledelayedexpansion

:askForKey
echo Enter the key (t for first 10 seconds, a for full MP3, s for split file):
set /p key=""

if "%key%"=="t" (
    echo You selected t: First 10 seconds.
) else if "%key%"=="a" (
    echo You selected a: Full MP3.
) else if "%key%"=="s" (
    echo You selected a: Split file.
	goto splitFile
) else (
    echo Invalid key. Please enter 't' or 'a'.
    goto askForKey
)

:: Debugging output
echo Key entered: "%key%"

:: Prompt user for the image file path
echo Enter the path to the image file:
set /p image_file=
set image_file=%image_file:"=%

:: Prompt user for the audio file path
echo Enter the path to the audio file:
set /p audio_file=

:: Remove any extra quotes from the input
set audio_file=%audio_file:"=%

:: Prompt user for the output video file name
echo Enter the output video file name:
set /p output_file=
set output_file=%output_file:"=%

echo %output_file% | findstr /r "\." >nul
if %errorlevel% neq 0 (
    :: If no extension is found, append ".mp4"
    set output_file=%output_file%.mp4
)
echo The output file name is: %output_file%


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
    echo Processing with first 10 seconds of audio...
    ffmpeg -loop 1 -i "%image_file%" -i "%audio_file%" -c:v libx264 -tune stillimage -preset ultrafast -b:v 500k -c:a copy -shortest -r 1 -t 10 "%output_file%"
	exit /b 1
) else if /i "%key%"=="a" (
    echo Key is 'a'
    echo Processing with full audio...
    ffmpeg -loop 1 -i "%image_file%" -i "%audio_file%" -c:v libx264 -tune stillimage -preset ultrafast -b:v 500k -c:a copy -shortest -r 1 "%output_file%"
	exit /b 1
)

:splitFile
echo Enter the input filename (with extension):
set /p input_file=


echo Enter the duration (format: HH:MM:SS):
set /p time=


rem Split the input into parts based on colons
for /F "tokens=1,2,3 delims=:" %%a in ("%time%") do (
    set part1=%%a
    set part2=%%b
    set part3=%%c
)

rem Determine the format and adjust accordingly
if defined part3 (
    rem Input is already in hh:mm:ss format, so just ensure it's correctly formatted
    set hours=!part1!
    set minutes=!part2!
    set seconds=!part3!
) else (
    rem Input is in mm:ss format, so add leading zeros for hours
    set hours=00
    set minutes=!part1!
    set seconds=!part2!
)


rem Ensure all parts are correctly formatted
if !minutes! lss 10 if not "!minutes:~0,1!"=="0" set minutes=0!minutes!
if !seconds! lss 10 if not "!seconds:~0,1!"=="0" set seconds=0!seconds!
if !hours! lss 10 if not "!hours:~0,1!"=="0" set hours=0!hours!

rem Output the result in hh:mm:ss format
set time=!hours!:!minutes!:!seconds!
echo Formatted time: !time!

ffmpeg -i "%input_file%" -t %time% -c copy "1_%input_file%"
ffmpeg -i "%input_file%" -ss %time% -c copy "2_%input_file%"
exit /b 1

endlocal
pause
