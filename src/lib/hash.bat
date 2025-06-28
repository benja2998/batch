@echo off
setlocal enabledelayedexpansion

echo "%~1" > "%TEMP%\temp.txt"
certutil -hashfile "%TEMP%\temp.txt" SHA256 > "%TEMP%\temp_hash.txt"

set count=0
for /f "delims=" %%a in ('type %TEMP%\temp_hash.txt') do (
    set /a count+=1
    if !count! equ 2 (
        set "hash=%%a"
    )
)

set "hash=!hash: =!"
set "hash=l!hash!"
set "hash=!hash:"=!"

echo !hash!> "%TEMP%\hash.txt"
exit /b