@echo off
setlocal enabledelayedexpansion

title compiler.bat

rem Check if scoop is installed
where scoop >nul 2>&1
if !errorlevel! neq 0 (
    echo Scoop is not installed. Installing Scoop...
    powershell -Command "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser; Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression"
    set "PATH=%USERPROFILE%\scoop\shims;%USERPROFILE%\scoop\bin;%PATH%"
) else (
    echo Scoop is already installed.
)

rem Check if nasm is installed
where nasm >nul 2>&1
if !errorlevel! neq 0 (
    echo NASM is not installed. Installing NASM using Scoop...
    scoop install nasm
    set "PATH=%USERPROFILE%\scoop\shims;%USERPROFILE%\scoop\bin;%USERPROFILE%\scoop\apps\nasm\current\bin;%PATH%"
    scoop reset nasm
) else (
    echo NASM is already installed.
)

rem Check if lld-link is installed
where lld-link >nul 2>&1
if !errorlevel! neq 0 (
    echo lld-link is not installed. Installing llvm using Scoop...
    scoop install llvm
    set "PATH=%USERPROFILE%\scoop\shims;%USERPROFILE%\scoop\bin;%USERPROFILE%\scoop\apps\llvm\current\bin;%PATH%"
    scoop reset llvm
) else (
    echo lld-link is already installed.
)

goto check_architecture

:check_architecture
set "source_file=%~1"
set "source_file_no_ext=%~n1"

echo Source file: !source_file!
set /p output_executable=Output executable file: 
if "!output_executable!"=="" (
    echo [31mError: File name cannot be empty[0m
    exit /b 1
)

rem Check if output_executable ends with .exe
set "ext=!output_executable:~-4!"
if /i not "!ext!"==".exe" (
    echo [31mError: Output file must have a .exe extension[0m
    exit /b 1
)

set "output_executable_no_ext=!output_executable!"
for %%F in ("!output_executable_no_ext!") do set "output_executable_no_ext=%%~nF"
echo Output executable without extension: !output_executable_no_ext!
set "output_asm_file=!output_executable_no_ext!.asm"

if not exist "!source_file!" (
    echo Source file "!source_file!" does not exist.
    exit /b 1
)

if exist "!output_asm_file!" (
    echo Output file "!output_asm_file!" already exists. Deleting it...
    del "!output_asm_file!"
)

echo extern ExitProcess >> "!output_asm_file!"
echo extern GetStdHandle >> "!output_asm_file!"

rem Check architecture
set "arch=!PROCESSOR_ARCHITECTURE!"
echo Detected architecture: !arch!

if /i "!arch!"=="AMD64" (
    echo Parsing for AMD64 architecture...
    goto parse
) else if /i "!arch!"=="ARM64" (
    echo Parsing for ARM64 architecture...
    echo The compiler will compile for AMD64 architecture. You can run the output file as Windows for ARM has AMD64 emulation.
    goto parse
) else (
    echo Unsupported architecture: !arch!
    exit /b 1
)

:parse
echo [1mParsing source file "!source_file!"...[0m

set "echo_included=false"
set "process_included=false"
set "command_silent=false"
set "section_data=false"
set "section_text=false"
set "is_label=false"

:: PARSE LOOP ::
for /f "tokens=*" %%i in ('type "!source_file!"') do (
    set "line=%%i"
    echo [1mParsing line: !line![0m

    rem Set command to first word in the line
    for /f "tokens=1,*" %%j in ("!line!") do (
        set "command=%%j"
        set "rest=%%k"
    )
    echo Initial command: !command!

    rem Check if command is silent (@)
    if "!command:~0,1!"=="@" (
        set "command_silent=true"
        echo Detected silent command.
    ) else (
        set "command_silent=false"
    )

    rem Check if it's a label (:)
    if "!command:~0,1!"==":" (
        set "is_label=true"
        set "command=!command:~1!"
        echo Detected label: !command!
        if "!command!"=="" (
            echo Error: Label cannot be empty.
            exit /b 1
        )
        if "!command!"==":" (
            echo Broken label detected, skipping...
            set "is_label=false"
            set "command="
        )
    ) else (
        set "is_label=false"
    )

    rem Remove '@' from silent command
    if "!command_silent!"=="true" (
        set "command=!command:~1!"
    )

    rem Skip empty command
    if "!command!"=="" (
        echo Empty command, skipping...
        set "is_label=false"
        set "command="
    )

    if "!command!"=="echo." (
        echo Detected echo command with no text.
        set "command=echo"
        set "rest=NEW_LINE"
    )

    rem Handle label
    if "!is_label!"=="true" (
        echo Label "!command!" will be handled later.
    ) else (
        rem Actual command handling
        if "!command!"=="echo" (
            echo Found echo command.
            if "!echo_included!"=="false" (
                echo Including WriteConsoleA...
                (
                    echo extern WriteConsoleA
                    type !output_asm_file!
                ) > "%TEMP%\temp.asm"
                move /y "%TEMP%\temp.asm" "!output_asm_file!" >nul
                set "echo_included=true"
            )

            rem Handle echo command

            if "!rest!"=="" (
                echo No text to echo, skipping...
            ) else (
                call "%~dp0lib\hash" "!rest!"
                for /f "usebackq delims=" %%A in ("%TEMP%\hash.txt") do set "hash=%%A"

                if "!section_data!"=="false" (
                    echo Adding section .data.
                    echo section .data >> "!output_asm_file!"
                    set "section_data=true"
                )

                rem Check if the !output_asm_file! contains !hash! db "!rest!", 0

                findstr /c:"!hash! db \"!rest!\", 0" "!output_asm_file!" >nul

                if !errorlevel! neq 0 (
                    echo Adding new text to ASM file
                    if "!rest!"=="NEW_LINE" (
                        echo    !hash! db 0x0D, 0x0A >> "!output_asm_file!"
                    ) else (
                        echo    !hash! db "!rest!", 0Dh, 0Ah, 0 >> "!output_asm_file!"
                    )
                    echo Adding new text to ASM file: !hash!_len equ $ - !hash!
                    echo    !hash!_len equ $ - !hash! >> "!output_asm_file!"
                ) else (
                    echo Text already exists in ASM file, skipping...
                )
            )
        ) else if "!command!"=="rem" (
            echo Skipping rem comment line.
        ) else if "!command!"=="exit" (
            echo Exit will be handled later.
        ) else if "!command!"=="goto" (
            echo Goto will be handled later.
        ) else (
            echo Non-echo/rem command detected: !command!
            if "!process_included!"=="false" (
                echo Including WinExec...
                (
                    echo extern WinExec
                    type !output_asm_file!
                ) > "%TEMP%\temp.asm"
                move /y "%TEMP%\temp.asm" "!output_asm_file!" >nul
                set "process_included=true"
            )
            
            call "%~dp0lib\hash" "!rest!"
            for /f "usebackq delims=" %%A in ("%TEMP%\hash.txt") do set "hash=%%A"

            if "!section_data!"=="false" (
                echo Adding section .data.
                echo section .data >> "!output_asm_file!"
                set "section_data=true"
            )

            set "rest=!rest:"=\"!"
            set "rest=cmd.exe /c @!command! !rest!"

            rem Check if the !output_asm_file! contains !hash! db "!rest!", 0

            findstr /c:"!hash! db \"!rest!\", 0" "!output_asm_file!" >nul

            if !errorlevel! neq 0 (
                echo Adding new text to ASM file
                if "!rest!"=="NEW_LINE" (
                    echo    !hash! db 0x0D, 0x0A >> "!output_asm_file!"
                ) else (
                    echo    !hash! db "!rest!", 0Dh, 0Ah, 0 >> "!output_asm_file!"
                )
                echo Adding new text to ASM file: !hash!_len equ $ - !hash!
                echo    !hash!_len equ $ - !hash! >> "!output_asm_file!"
            ) else (
                echo Text already exists in ASM file, skipping...
            )
        )
    )
)

echo [1mParsing complete. Compiling file "!source_file!" to ASM file "!output_asm_file!"...[0m

if "!section_text!"=="false" (
    echo Adding section .text.
    echo section .text >> "!output_asm_file!"
    echo    global _start >> "!output_asm_file!"
    echo _start: >> "!output_asm_file!"
    set "section_text=true"
)

:: Start timing compilation
set "starttime=%time%"

:: COMPILE LOOP ::
for /f "tokens=*" %%i in ('type "!source_file!"') do (
    set "line=%%i"
    echo [1mCompiling line: !line![0m

    rem Set command to first word in the line
    for /f "tokens=1,*" %%j in ("!line!") do (
        set "command=%%j"
        set "rest=%%k"
    )

    rem Check if command is silent (@)
    if "!command:~0,1!"=="@" (
        set "command_silent=true"
    ) else (
        set "command_silent=false"
    )

    rem Check if it's a label (:)
    if "!command:~0,1!"==":" (
        set "is_label=true"
        set "command=!command:~1!"
        if "!command!"==":" (
            echo Broken label detected. Skipping...
            set "is_label=false"
            set "command="
        )
    ) else (
        set "is_label=false"
    )

    rem Remove '@' from silent command
    if "!command_silent!"=="true" (
        set "command=!command:~1!"

        if "!command!"=="echo" (
            rem TODO: implement proper handling
            if "!rest!"=="off" (
                set "rest="
            ) else if "!rest!"=="on" (
                set "rest="
            )
        )
    )

    rem Skip empty command
    if "!command!"=="" (
        echo Empty command. Skipping...
        set "is_label=false"
        set "command="
    )

    if "!command!"=="echo." (
        set "command=echo"
        set "rest=NEW_LINE"
    )

    rem Implement command handling
    if "!is_label!"=="true" (
        echo !command!: >> "!output_asm_file!"
    ) else (
        if "!command!"=="echo" (
            if not "!rest!"=="" (
                call "%~dp0lib\hash" "!rest!"
                for /f "usebackq delims=" %%A in ("%TEMP%\hash.txt") do set "hash=%%A"

                >> "!output_asm_file!" (
                    echo ; echo !rest!
                    echo sub rsp, 40
                    echo mov ecx, -11
                    echo call GetStdHandle
                    echo mov rbx, rax
                    echo mov rcx, rbx
                    echo lea rdx, [rel !hash!]
                    echo mov r8d, !hash!_len
                    echo xor r9, r9
                    echo mov qword [rsp+32], 0
                    echo call WriteConsoleA
                    echo add rsp, 40
                )
                echo [32mCompiled echo command successfully[0m
            ) else (
                echo [33mNo text to echo, skipping...[0m
            )
        ) else if "!command!"=="exit" (
            >> "!output_asm_file!" (
                echo ; exit
                echo xor ecx, ecx
                echo call ExitProcess
            )
            echo [32mCompiled exit command successfully[0m
        ) else if "!command!"=="goto" (
            if not "!rest!"=="" (
                >> "!output_asm_file!" (
                    echo ; goto !rest!
                    echo jmp !rest!
                )
                echo [32mCompiled goto command successfully[0m
            ) else (
                echo [31mError: goto requires a label.[0m
                exit /b 1
            )
        ) else if "!command!"=="rem" (
            echo Skipping remark...
        ) else (
            if "!command!"=="" (
                rem Nothing
            ) else (
                rem WinExec fallback for unrecognized commands
                echo Treating as WinExec command: !command! !rest!
                
                call "%~dp0lib\hash" "!rest!"
                for /f "usebackq delims=" %%A in ("%TEMP%\hash.txt") do set "hash=%%A"
    
                if "!section_data!"=="false" (
                    echo section .data >> "!output_asm_file!"
                    set "section_data=true"
                )
    
                >> "!output_asm_file!" (
                    echo ; !command! !rest!
                    echo sub rsp, 32
                    echo lea rcx, [rel !hash!]
                    echo mov edx, 1  ; SW_SHOWNORMAL
                    echo and rsp, -16
                    echo call WinExec
                    echo add rsp, 32
                )

                echo [32mCompiled WinExec command successfully[0m
            )
        )
    )
)

(
    echo ; Compiled from !source_file! by the "compiler.bat" compiler.
    echo ; This is NOT the original source code.
    type "!output_asm_file!"
) > "%TEMP%\temp.asm"
move /y "%TEMP%\temp.asm" "!output_asm_file!" >nul

echo Running: nasm -f win64 "!output_asm_file!" -o "!output_executable_no_ext!.obj"

nasm -f win64 "!output_asm_file!" -o "!output_executable_no_ext!.obj"

echo Running: lld-link "!output_executable_no_ext!.obj" kernel32.lib /subsystem:console /entry:_start /out:"!output_executable!"

lld-link "!output_executable_no_ext!.obj" kernel32.lib /subsystem:console /entry:_start /out:"!output_executable!"

echo Deleting temporary files...

rem Only run del "!output_asm_file!" /s /q >nul 2>&1 if %~2 is not set to "keep_asm"
if not "%~2"=="keep_asm" (
    del "!output_asm_file!" /s /q >nul 2>&1
) else (
    echo Not deleting .asm file as keep_asm is the second argument
)
del "!output_executable_no_ext!.obj" /s /q >nul 2>&1
del "%TEMP%\temp.txt" /s /q >nul 2>&1
del "%TEMP%\temp_hash.txt" /s /q >nul 2>&1
del "%TEMP%\hash.txt" /s /q >nul 2>&1
del "%TEMP%\temp.asm" /s /q >nul 2>&1

:: End timing compilation
set "endtime=%time%"

:: Calculate elapsed time
call :TimeDiff "%starttime%" "%endtime%" elapsed

echo [1mCompilation time: !elapsed![0m

exit /b

:: Function to calculate time difference between %1=start and %2=end in HH:MM:SS.xx format, output in variable %3
:TimeDiff
setlocal
set "start=%~1"
set "end=%~2"

rem Parse start time
for /f "tokens=1-4 delims=:.," %%a in ("%start%") do (
    set /a "sh=1%%a - 100"
    set /a "sm=1%%b - 100"
    set /a "ss=1%%c - 100"
    set /a "sf=1%%d - 100"
)

rem Parse end time
for /f "tokens=1-4 delims=:.," %%a in ("%end%") do (
    set /a "eh=1%%a - 100"
    set /a "em=1%%b - 100"
    set /a "es=1%%c - 100"
    set /a "ef=1%%d - 100"
)

rem Convert start and end to centiseconds
set /a "start_cs=(((sh*60)+sm)*60+ss)*100+sf"
set /a "end_cs=(((eh*60)+em)*60+es)*100+ef"

rem Calculate difference (handle midnight wrap)
set /a "diff=end_cs - start_cs"
if %diff% lss 0 set /a "diff+=24*60*60*100"

rem Convert back to HH:MM:SS.cc
set /a "dh=diff/(60*60*100)"
set /a "dm=(diff/(60*100))%%60"
set /a "ds=(diff/100)%%60"
set /a "df=diff%%100"

endlocal & set "%~3=%dh%:%dm:~-2%:%ds:~-2%.%df:~-2%"
goto :eof
