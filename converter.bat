@echo off
setlocal enabledelayedexpansion
REM setting the window size according to gui
mode con: cols=88 lines=40
REM Define the maximum length for filenames in each column
set max_length=25


for /f "tokens=4-5 delims=[.] " %%i in ('ver') do (
    set version_major=%%i
    set version_minor=%%j
)

if "%version_major%.%version_minor%"=="6.1" (
    REM echo Windows 7 detected. ANSI colors not supported.
	set "colorYellow"=""
	set "colorGreen"=""
	set "colorCyan"=""
	set "colorReset"=""
	set "colorRed"=""
) else (
    REM echo This is not Windows 7. Hopefully ANSI colors can be used
	set "colorYellow=[93m"
	set "colorGreen=[92m"
	set "colorCyan=[96m"
	set "colorReset=[0m"
	set "colorRed=[91m"
)

:start
cls
:askForKey
echo =======================================================================================
echo.Program    available media work with                             didzis@lauvadidzis.com
echo =======================================================================================
echo.
echo Possible keys to proceed:
echo.
echo %colorCyan%t %colorReset%: first 10 seconds (with audio normalization),
echo %colorYellow%a %colorReset%: full MP3 to video (with sound normalization), 
echo %colorCyan%af%colorReset%: fast full MP3 to video (no sound normalization), 
echo %colorYellow%s %colorReset%: split media file, 
echo %colorCyan%m %colorReset%: merge media files in filelist %colorCyan%list.txt%colorReset%,
echo %colorYellow%te%colorReset%: trim the end of the media files from certain timecode,
echo %colorCyan%tb%colorReset%: trim the beginning of the media files from certain timecode,
echo %colorYellow%ss%colorReset%: split and swap media at certain timecode,
echo %colorCyan%na%colorReset%: extract and normalize audio stream,
echo %colorYellow%ex%colorReset%: extract a portion of media file,
echo %colorCyan%ra%colorReset%: reencode mp3,
echo %colorYellow%r%colorReset% : refresh the file list,
echo %colorCyan%q %colorReset%: quit.
echo.



REM Create headers

echo =======================================================================================
echo File list for available media work with %colorGreen%ffmpeg.exe%colorReset%
echo.
echo %colorYellow%Images:%colorReset%                      %colorGreen%Audio:%colorReset%                       %colorCyan%Video:%colorReset%
echo _______________________________________________________________________________________
echo.

REM Initialize counters
set img_count=0
set aud_count=0
set vid_count=0

REM Arrays to store filenames
for %%i in (*.jpg *.jpeg *.png *.gif *.bmp *.tiff *.tif) do (
    set /a img_count+=1
    set "img[!img_count!]=%%i"
)

for %%i in (*.mp3 *.wav *.wma *.aac *.flac *.ogg *.m4a) do (
    set /a aud_count+=1
    set "aud[!aud_count!]=%%i"
)

for %%i in (*.mp4 *.avi *.mkv *.mov *.wmv *.flv *.mpeg *.mpg *.webm) do (
    set /a vid_count+=1
    set "vid[!vid_count!]=%%i"
)

REM Find the max count to determine loop iterations
set max_count=%img_count%
if %aud_count% gtr %max_count% set max_count=%aud_count%
if %vid_count% gtr %max_count% set max_count=%vid_count%

REM Print the table
for /L %%i in (1,1,%max_count%) do (
    set "img_display="
    set "aud_display="
    set "vid_display="

    REM Handle truncation and padding within the loop only if variables are defined
    if defined img[%%i] (
        set "img_display=!img[%%i]!"
        if not "!img_display:~%max_length%,1!"=="" (
            set "img_display=!img_display:~0,%max_length%!...!"
        )
        set "img_display=!img_display:~0,%max_length%!"
    )

    if defined aud[%%i] (
        set "aud_display=!aud[%%i]!"
        if not "!aud_display:~%max_length%,1!"=="" (
            set "aud_display=!aud_display:~0,%max_length%!...!"
        )
        set "aud_display=!aud_display:~0,%max_length%!"
    )

    if defined vid[%%i] (
        set "vid_display=!vid[%%i]!"
        if not "!vid_display:~%max_length%,1!"=="" (
            set "vid_display=!vid_display:~0,%max_length%!...!"
        )
        set "vid_display=!vid_display:~0,%max_length%!"
    )

    REM Pad each column to align properly
    set "img_display=!img_display!                                             "
    set "aud_display=!aud_display!                                             "
    set "vid_display=!vid_display!                                             "

    REM Print the row even if one or more columns are empty
    echo !img_display:~0,%max_length%!    !aud_display:~0,%max_length%!    !vid_display:~0,%max_length%!
)
echo.
echo =======================================================================================
echo.
echo.



set /p key="Enter your choice: "

if "%key%"=="t" (
    echo You selected t: First 10 seconds.
) else if "%key%"=="a" (
    echo You selected a: Full MP3. With sound normalization filter.
) else if "%key%"=="af" (
    echo You selected a: Fast Full MP3. Without sound normalization.
) else if "%key%"=="s" (
    echo You selected a: Split file.
	goto trimSplitSwapFile
) else if "%key%"=="m" (
    echo You selected a: Merge files from list.
	goto mergeFiles
) else if "%key%"=="te" (
    echo You selected te: Trim end in file.
	goto trimSplitSwapFile
) else if "%key%"=="tb" (
    echo You selected tb: Trim beginning in file.
	goto trimSplitSwapFile
) else if "%key%"=="ss" (
    echo You selected ss: Split, swap and merge.
	goto trimSplitSwapFile
) else if "%key%"=="na" (
    echo You selected na: Normalize audio.
	goto normalizeAudio
) else if "%key%"=="ex" (
    echo You selected ex: Extracting a portion.
	goto extractPortion
) else if "%key%"=="r" (
    echo You selected r: Refreshing the filelist.
	goto start
) else if "%key%"=="ra" (
    echo You selected r: Refreshing the filelist.
	goto reencodeAudio
) else if "%key%"=="q" (
    echo Exiting.
	pause
	exit /b 1
) else (
    echo Invalid key. Please enter 't' or 'a'.
    goto askForKey
)

:: Prompt user for the image file path
:testOrAll
	:loopimageq
	echo Enter the full %colorYellow%image%colorReset% file name (with extension. TAB key completes the filename):
	set /p image_file=
	set image_file=%image_file:"=%
	echo.

	:: Check if the image file exists
	if not exist "%image_file%" (
		echo The image file does not exist.
		goto loopimageq
		exit /b 1
	)

	:: Check if the file matches any of the specified extensions
	set "valid=0"
	for %%x in (jpg jpeg png gif bmp tiff tif) do (
		if /i "!image_file:~-4!"==".%%x" set "valid=1"
		if /i "!image_file:~-5!"==".%%x" set "valid=1"
	)

	if "%valid%"=="0" (
		echo The file is %colorRed%not a valid image%colorReset% file.
		goto loopimageq
	)

	:loopaudioq
	:: Prompt user for the audio file path
	echo Enter the full %colorGreen%audio%colorReset% file name (with extension):
	set /p audio_file=
	set audio_file=%audio_file:"=%
	echo.
	:: Check if the image file exists
	if not exist "%audio_file%" (
		echo The image file does not exist.
		goto loopimageq
		exit /b 1
	)

	:: Check if the file matches any of the specified extensions
	set "valid=0"
	for %%x in (mp3 wav wma aac flac ogg m4a) do (
		if /i "!audio_file:~-4!"==".%%x" set "valid=1"
	)

	if "%valid%"=="0" (
		echo The file is %colorRed%not a valid audio%colorReset% file.
		goto loopaudioq
	)

	:: Prompt user for the output video file name
	echo Enter the %colorCyan%output video%colorReset% file name (if no extension present, default is %colorCyan%mp4%colorReset%):
	set /p output_file=
	set output_file=%output_file:"=%


	echo %output_file% | findstr /r "\." >nul
	if %errorlevel% neq 0 (
		:: If no extension is found, append ".mp4"
		set output_file=%output_file%.mp4
	)
	echo.




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
		
		ffmpeg -loop 1 -i "%image_file%" -i "%audio_file%" -c:v libx264 -tune stillimage -preset ultrafast -b:v 500k -af "loudnorm=I=-16:TP=-1.5:LRA=11" -shortest -r 1 -t 10 "%output_file%"
		
		goto Prompt

	) else if /i "%key%"=="a" (
		echo Key is 'a'
		echo Processing with full "normalize" audio...
		ffmpeg -loop 1 -i "%image_file%" -i "%audio_file%" -c:v libx264 -tune stillimage -preset ultrafast -b:v 500k -af "loudnorm=I=-16:TP=-1.5:LRA=11" -shortest -r 1 "%output_file%"
		goto Prompt
		
	) else if /i "%key%"=="af" (
		echo Key is 'a'
		echo Processing with full "copy" audio...
		ffmpeg -loop 1 -i "%image_file%" -i "%audio_file%" -c:v libx264 -tune stillimage -preset ultrafast -b:v 500k -c:a libmp3lame -shortest -r 1 "%output_file%"
		goto Prompt
	)

:reencodeAudio
	echo.
	echo Enter the input filename (with extension):
	set /p input_file=
	set input_file=%input_file:"=%

	for %%a in ("%input_file%") do (
			set name=%%~na
			set ext=%%~xa
		)


	for %%b in (.mp4 .mkv .avi .mov .wmv .flv .m4v) do (
		if /I "%ext%"=="%%b" set type=video
	)

	for %%b in (.mp3 .wav .flac .aac .ogg .m4a .wma) do (
		if /I "%ext%"=="%%b" set type=audio
	)
	
	echo Normalize audio? (y/n):
	set /p normalize=
	
	if "%normalize%"=="y" (
		ffmpeg -i %input_file% -c:a libmp3lame -af "loudnorm=I=-16:TP=-1.5:LRA=11" -b:a 128k %name%_reencoded_normalized%ext%
	) else (
		ffmpeg -i %input_file% -c:a libmp3lame -b:a 128k %name%_reencoded%ext%
	)
	
	goto Prompt


:trimSplitSwapFile
	echo.
	echo Enter the input filename (with extension):
	set /p input_file=
	set input_file=%input_file:"=%


	for %%a in ("%input_file%") do (
			set name=%%~na
			set ext=%%~xa
		)


	for %%b in (.mp4 .mkv .avi .mov .wmv .flv .m4v) do (
		if /I "%ext%"=="%%b" set type=video
	)

	for %%b in (.mp3 .wav .flac .aac .ogg .m4a .wma) do (
		if /I "%ext%"=="%%b" set type=audio
	)


	:chooseTime
	echo Enter the timecode (format: HH:MM:SS or MM:SS):
	set /p time=

	if "%time%"=="q" (
		echo Exiting
		pause
		exit /b 1
	) 
		
	rem Split the input into parts based on colons
	for /F "tokens=1,2,3 delims=:" %%a in ("%time%") do (
		set part1=%%a
		set part2=%%b
		set part3=%%c
	)

	if not defined part2 (
		echo %colorRed%Not proper timecode%colorReset%
		goto chooseTime
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

	if "!key!"=="te" (
		echo You selected trim
		set output_file=%name%_trimmed_end%ext%
		ffmpeg -i "%input_file%" -t %time% -c copy "!output_file!"
		goto Prompt
	) else if "!key!"=="tb" (
		echo You selected trim
		set output_file=%name%_trimmed_beginning%ext%
		ffmpeg -i "%input_file%" -ss %time% -c:v libx264 -preset ultrafast -c:a copy "!output_file!"
		goto Prompt
	) else if "!key!"=="s" (
		echo You selected split
		set output_file=%name%_A%ext%
		ffmpeg -i "%input_file%" -t %time% -c copy "!output_file!"
		set output_file=%name%_B%ext%
		ffmpeg -i "%input_file%" -ss %time% -c:v libx264 -preset ultrafast -c:a copy !output_file!"
		goto Prompt

	) else if "!key!"=="ss" (	
		if "!type!"=="audio" (
			ffmpeg -i "%input_file%" -t %time% -c copy "%name%_A%ext%"
			ffmpeg -i "%input_file%" -ss %time% -c copy "%name%_B%ext%"	
			
			ffmpeg -i "concat:%name%_B%ext%|%name%_A%ext%" -acodec copy %name%_swapped%ext%
			del %name%_B%ext%
			del %name%_A%ext%
		)	else (
		
			ffmpeg -i "%input_file%" -t %time% -c:v libx264 -preset ultrafast -c:a copy "%name%_A%ext%"
			ffmpeg -i "%input_file%" -ss %time% -c:v libx264 -preset ultrafast -c:a copy "%name%_B%ext%"
			
			ffmpeg -i %name%_B%ext% -i %name%_A%ext% -filter_complex "[0:0][0:1][1:0][1:1]concat=n=2:v=1:a=1[outv][outa]" -map "[outv]" -map "[outa]" %name%_swapped%ext%
			del %name%_B%ext%
			del %name%_A%ext%
		)
		
		echo Split and swap successful. !name!_swapped!ext! created.
		
		
		goto Prompt
	)




:mergeFiles

	echo Enter the %colorGreen%out%colorCyan%put%colorReset% media file name:
	set /p output_file=
	set output_file=%output_file:"=%

	echo %output_file% | findstr /r "\." >nul
	if %errorlevel% neq 0 (
		:: If no extension is found, append ".mp4"
		set output_file=%output_file%.mp4
	)
	echo The %colorGreen%out%colorCyan%put%colorReset% file name is: %output_file%


	REM Path to the file to check
	set "file=list.txt"
	set "errorFound=false"

	REM Check if the file exists first
	if exist "%file%" (
		REM Initialize line count variable
		set "lineCount=0"

		REM Loop through each line in the file to count the lines
		for /f "usebackq delims=" %%A in ("%file%") do (
			set /a lineCount=!lineCount!+1
		)

		REM Check if the line count is zero
		if !lineCount! equ 0 (
			echo The file "%file%" is empty.
		) else (
			echo The file "%file%" has !lineCount! lines.
		)
	) else (
		echo %colorRed%The file "%file%" does not exist.%colorReset%
		
		set /p keys="To continue and create file with filenames press %colorYellow%c%colorReset%. Press %colorRed%q%colorReset% to quit: "
		
		if "!keys!"=="q" (
			echo exiting
			pause
			exit /b 1
		) else if "!keys!"=="c" (
			echo.
			goto prepareMergeFile
		)
	)
	REM Flag to track if any errors are found

	:lineLoop
	REM Loop through each line in the file
	echo.
	echo Checking file list.txt
	for /f "usebackq delims=" %%a in ("%file%") do (
		REM Print the current line
		REM Check if the line matches the pattern using findstr
		echo %%a | findstr /r "^file '.*\.mp3'$" >nul
		if errorlevel 1 (
			echo %colorRed%ERROR%colorReset%: %%a
			set "errorFound=true"
		) else (
			echo %colorGreen%OK%colorReset%   : %%a
		)
	)
	echo.
	REM Final message after processing all lines
	if "%errorFound%"=="true" (
		echo %colorRed%Some lines did not match the expected format.%colorReset%
		pause
		exit /b 1
	) else (
		echo %colorGreen%All lines match the expected format.%colorReset%
	:editLoop
		set /p keys="To %colorYellow%merge%colorReset% existing, press %colorYellow%m%colorReset%. To %colorGreen%edit%colorReset% list.txt file, press %colorGreen%e%colorReset% :"
		
		if "!keys!"=="e" (
			goto prepareMergeFile
		) else if "!keys!"=="m" (
			goto mergeFileX
		) else (
		goto editLoop
		)
	)


	:prepareMergeFile
	REM Ask the user how many inputs they want
	set /p inputCount="How %colorYellow%many%colorReset% media files do you want to merge? (Enter %colorYellow%number%colorReset% or %colorGreen%q%colorReset% to quit)"

	REM Initialize a counter
	set "counter=1"

	if "%inputCount%"=="q" (
		echo Exiting.
		pause
		exit /b 1
	)

	REM Check if the file exists before deleting it
	if exist "%file%" (
		del "%file%"
	) 

	REM Loop to collect inputs from the user
	:inputLoop
	if !counter! leq %inputCount% (
		:fileCheck
		set /p userInput="Enter input !counter!: "
		
		if not exist "!userInput!" (
			echo File "!userInput!" %colorRed%does not exist%colorReset%. Please enter a valid filename.
			goto fileCheck
		)
		
		
		echo file '!userInput!' >> %file%
		set /a counter+=1
		goto inputLoop
	)

	echo All media filenames have been saved successfully to list.txt


	:mergeFileX
	ffmpeg -f concat -safe 0 -i list.txt -c copy "%output_file%"
	goto Prompt

:normalizeAudio
	echo.
	echo.
	echo.
	:loopNAQ
	echo Enter the input filename (with extension):
	set /p input_file=
	set input_file=%input_file:"=%
	
	:: Check if the image file exists
	if not exist "%input_file%" (
		echo The media file does not exist.
		goto loopNAQ
		exit /b 1
	)
	
	:: Check if the file matches any of the specified extensions
	set "valid=0"
	for %%x in (mp3 wav wma aac flac ogg m4a mp4 mkv avi mov wmv flv m4v) do (
		if /i "!input_file:~-4!"==".%%x" set "valid=1"
	)

	if "%valid%"=="0" (
		echo The file is %colorRed%not a valid audio%colorReset% file.
		goto loopNAQ
	)

	for %%a in ("%input_file%") do (
			set name=%%~na
			set ext=%%~xa
		)
	echo ir
	
	ffmpeg -i "%input_file%" -af "loudnorm=I=-16:TP=-1.5:LRA=11" -c:a libmp3lame -b:a 128k "%name%_norm.mp3"
	goto Prompt
	

:extractPortion
	echo.
	echo.
	echo.
	:loopNAQ
	echo Enter the input filename (with extension):
	set /p input_file=
	set input_file=%input_file:"=%
	
	:: Check if the image file exists
	if not exist "%input_file%" (
		echo The media file does not exist.
		goto loopNAQ
		exit /b 1
	)
	
	:: Check if the file matches any of the specified extensions
	set "valid=0"
	for %%x in (mp3 wav wma aac flac ogg m4a mp4 mkv avi mov wmv flv m4v) do (
		if /i "!input_file:~-4!"==".%%x" set "valid=1"
	)

	if "%valid%"=="0" (
		echo The file is %colorRed%not a valid audio%colorReset% file.
		goto loopNAQ
	)

	for %%a in ("%input_file%") do (
			set name=%%~na
			set ext=%%~xa
		)
		
	for %%b in (.mp4 .mkv .avi .mov .wmv .flv .m4v) do (
		if /I "%ext%"=="%%b" set type=video
	)

	for %%b in (.mp3 .wav .flac .aac .ogg .m4a .wma) do (
		if /I "%ext%"=="%%b" set type=audio
	)
	
	set counter=1
	:chooseBeginningTimeForExtract
	echo Enter the timecode (format: HH:MM:SS or MM:SS):
	set /p time=

	if "%time%"=="q" (
		echo Exiting
		pause
		exit /b 1
	) 
		
	rem Split the input into parts based on colons
	for /F "tokens=1,2,3 delims=:" %%a in ("%time%") do (
		set part1=%%a
		set part2=%%b
		set part3=%%c
	)

	if not defined part2 (
		echo %colorRed%Not proper timecode%colorReset%
		goto chooseBeginningTimeForExtract
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
	set beginningTime=!hours!:!minutes!:!seconds!
	echo Formatted time: !beginningTime!
	
	
	:chooseEndTimeForExtract
	echo Enter the timecode (format: HH:MM:SS or MM:SS):
	set /p time=

	if "%time%"=="q" (
		echo Exiting
		pause
		exit /b 1
	) 
		
	rem Split the input into parts based on colons
	for /F "tokens=1,2,3 delims=:" %%a in ("%time%") do (
		set part1=%%a
		set part2=%%b
		set part3=%%c
	)

	if not defined part2 (
		echo %colorRed%Not proper timecode%colorReset%
		goto chooseEndTimeForExtract
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
	set endTime=!hours!:!minutes!:!seconds!
	echo Formatted time: !endTime!
	echo !type!
	if "!type!"=="audio" (
			ffmpeg -i %input_file% -ss %beginningTime% -to %endTime% -c copy %name%_portion!counter!%ext%
		)	else (
			ffmpeg -i %input_file% -ss %beginningTime% -to %endTime% -c:v libx264 -preset ultrafast -c:a copy %name%_portion!counter!%ext%
		)
		
	::  extract another portion?
	echo.
	echo.
	echo Press e to extract another portion or 
	echo Enter to go return to beginning or 
	echo q to quit:
	set /p key=

	if "%key%"=="q" (
		echo Exiting
		pause
		exit /b 1
	) else if "%key%"=="e" (
		set /a counter+=1
		goto chooseBeginningTimeForExtract
	) else (	
		goto start
	)


:Prompt
	echo.
	echo.
	echo Do you want to restart (%colorYellow%r%colorReset%) again or quit (%colorRed%q%colorReset%)?
	set /p "choice=Enter your choice: "

	if /i "%choice%"=="r" (
		goto start
	) else if /i "%choice%"=="q" (
		exit
	) else (
		echo Invalid choice! Please enter "s" or "q".
		pause
		goto Prompt
	)

endlocal
