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
echo Output ASM file: !source_file_no_ext!.asm

if not exist "!source_file!" (
    echo Source file "!source_file!" does not exist.
    exit /b 1
)

if exist "!source_file_no_ext!.asm" (
    echo Output file "!source_file_no_ext!.asm" already exists. Deleting it...
    del "!source_file_no_ext!.asm"
)

echo extern ExitProcess >> "!source_file_no_ext!.asm"
echo extern GetStdHandle >> "!source_file_no_ext!.asm"

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
echo Parsing source file "!source_file!"...

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
                    type !source_file_no_ext!.asm
                ) > "%TEMP%\temp.asm"
                move /y "%TEMP%\temp.asm" "!source_file_no_ext!.asm" >nul
                set "echo_included=true"
            )

            rem Handle echo command

            if "!rest!"=="" (
                echo No text to echo, skipping...
            ) else (
                echo "!rest!" > "%TEMP%\temp.txt"
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

                if "!section_data!"=="false" (
                    echo Adding section .data.
                    echo section .data >> "!source_file_no_ext!.asm"
                    set "section_data=true"
                )

                rem Check if the !source_file_no_ext!.asm contains !hash! db "!rest!", 0

                findstr /c:"!hash! db \"!rest!\", 0" "!source_file_no_ext!.asm" >nul

                if !errorlevel! neq 0 (
                    echo Adding new text to ASM file
                    if "!rest!"=="NEW_LINE" (
                        echo    !hash! db 0x0D, 0x0A >> "!source_file_no_ext!.asm"
                    ) else (
                        echo    !hash! db "!rest!", 0Dh, 0Ah, 0 >> "!source_file_no_ext!.asm"
                    )
                    echo Adding new text to ASM file: !hash!_len equ $ - !hash!
                    echo    !hash!_len equ $ - !hash! >> "!source_file_no_ext!.asm"
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
                    type !source_file_no_ext!.asm
                ) > "%TEMP%\temp.asm"
                move /y "%TEMP%\temp.asm" "!source_file_no_ext!.asm" >nul
                set "process_included=true"
            )
        )
    )
)

echo [1mParsing complete. Compiling file "!source_file!" to ASM file "!source_file_no_ext!.asm"...[0m

if "!section_text!"=="false" (
    echo Adding section .text.
    echo section .text >> "!source_file_no_ext!.asm"
    echo    global _start >> "!source_file_no_ext!.asm"
    echo _start: >> "!source_file_no_ext!.asm"
    set "section_text=true"
)

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
        echo !command!: >> "!source_file_no_ext!.asm"
    ) else (
        if "!command!"=="echo" (
            if not "!rest!"=="" (
                echo "!rest!" > "%TEMP%\temp.txt"
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

                >> "!source_file_no_ext!.asm" (
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
                echo Compiled echo command successfully
            ) else (
                echo No text to echo, skipping...
            )
        ) else if "!command!"=="exit" (
            >> "!source_file_no_ext!.asm" (
                echo ; exit
                echo xor ecx, ecx
                echo call ExitProcess
            )
            echo Compiled exit command successfully
        ) else if "!command!"=="goto" (
            if not "!rest!"=="" (
                >> "!source_file_no_ext!.asm" (
                    echo ; goto !rest!
                    echo jmp !rest!
                )
                echo Compiled goto command successfully
            ) else (
                echo Error: goto requires a label.
                exit /b 1
            )
        )
    )
)

(
    echo ; AUTOMATICALLY GENERATED FILE. DO NOT EDIT. EDIT !source_file_no_ext!.bat INSTEAD.
    type "!source_file_no_ext!.asm"
) > "%TEMP%\temp.asm"
move /y "%TEMP%\temp.asm" "!source_file_no_ext!.asm" >nul

echo Running: nasm -f win64 "!source_file_no_ext!.asm" -o "!source_file_no_ext!.obj"

nasm -f win64 "!source_file_no_ext!.asm" -o "!source_file_no_ext!.obj"

echo Running: lld-link "!source_file_no_ext!.obj" kernel32.lib /subsystem:console /entry:_start /out:"!source_file_no_ext!.exe"

lld-link "!source_file_no_ext!.obj" kernel32.lib /subsystem:console /entry:_start /out:"!source_file_no_ext!.exe"

echo Deleting temporary files...

rem Only run del "!source_file_no_ext!.asm" /s /q >nul 2>&1 if %~2 is not set to "keep_asm"
if not "%~2"=="keep_asm" (
    del "!source_file_no_ext!.asm" /s /q >nul 2>&1
) else (
    echo Not deleting .asm file as keep_asm is the second argument
)
del "!source_file_no_ext!.obj" /s /q >nul 2>&1
del "%TEMP%\temp.txt" /s /q >nul 2>&1
del "%TEMP%\temp_hash.txt" /s /q >nul 2>&1
del "%TEMP%\temp.asm" /s /q >nul 2>&1

echo Compilation complete. Output file: "!source_file_no_ext!.exe"