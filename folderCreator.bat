@echo off
setlocal

:: Prompt for start number
set /p startNum=What's the start number? 

:: Prompt for count
set /p count=What's the count? 

:: Prompt for prefix
set /p prefix=What's the prefix? 

:: Convert start number and count to integers
set /a endNum=%startNum% + %count%

:: Loop to create folders
for /l %%i in (%startNum%,1,%endNum%) do (
    md "%prefix%%%i"
)

echo Folders created from %prefix%%startNum% to %prefix%%endNum%!
pause