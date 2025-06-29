param (
    [string]$InputFile,
    [string]$OutputAsmFile
)

$redirect_stdout = ""
$command = ""
$rest = ""
$command_silent = $false
$is_label = $false
$file = ""

# This is NOT the standalone compiler.
# You must launch compiler.bat instead.

function Show-Input {
    
}

Get-Content $InputFile | ForEach-Object {
    Write-Host "[1mCompiling line $_[0m"
    # Reset variables to prevent conflicts
    $redirect_stdout = ""
    $command = ""
    $rest = ""
    $command_silent = $false
    $is_label = $false
    $file = ""

    # Set command to first word in $_
    $command = $_.Split(' ')[0]
    # Set rest of the line as the rest of the command
    $rest = $_.Substring($_.IndexOf($command) + $command.Length).Trim()
    # Check for output redirection
    # These redirect stdout to a file or device

    if ($_ -match '^(?<command>\S+)\s+(?<redirect>\S+)\s+(?<file>\S+)$') {
        $command = $Matches['command']
        $redirect = $Matches['redirect']
        $file = $Matches['file']

        # Handle output redirection

        if ($redirect -eq '>') {
            $redirect_stdout = 'overwrite'
        } elseif ($redirect -eq '>>') {
            $redirect_stdout = 'append'
        }
    }

    # See if command is silent (@)
    if ($command -match '^@') {
        $command_silent = $true
        # Remove '@' from silent command
        $command = $command.Substring(1)
    }

    # Check if it's a label (:)
    if ($command -match '^:') {
        $is_label = $true
        $command = $command.Substring(1)
        if ($command -eq ':') {
            Write-Host "Broken label detected. Skipping..."
            $is_label = $false
            $command = ''
        }
    }
    
    # Check if command is rem
    if ($command -eq 'rem') {
        Write-Host "Skipping remark..."
        $command = ''
    }

    # Check if silent command is echo
    if ($command_silent -and $command -eq 'echo') {
        if ($rest -eq '') {
            Write-Host "No text to echo, skipping..." -ForegroundColor Yellow
            continue
        } else {
            # Check if the rest if "off" or "on"
            if ($rest -eq 'off') {
                $command_silent = $false
            } elseif ($rest -eq 'on') {
                $command_silent = $true
            }
        }
    }

    # Check if command is echo.

    if ($command -eq 'echo.') {
        $command = 'echo'
        $rest = 'NEW_LINE'
        Write-Host "Command is a new line"
    }

    if ($is_label -ne $true -and $command -ne '') {
        # Check if command is exit
        if ($command -eq 'exit') {
            Write-Host "Compiling exit command..."
            Add-Content -Path $OutputAsmFile -Value "
; exit
xor ecx, ecx
call ExitProcess
            "
            Write-Host "Compiled exit command successfully" -ForegroundColor Green
        } elseif ($command -eq 'goto') {
            if ($rest -ne '') {
                Write-Host "Compiling goto command..."
                Add-Content -Path $OutputAsmFile -Value "
; goto $rest
jmp $rest
                "
                Write-Host "Compiled goto command successfully" -ForegroundColor Green
            } else {
                Write-Host "Error: goto requires a label." -ForegroundColor Red
                exit 1
            }
        } elseif ($command -eq 'echo') {
            Write-Host "Compiling echo command..."

            if ($rest -eq '') {
                Write-Host "No text to echo, skipping..." -ForegroundColor Yellow
                continue
            }

            # Hash the rest of the line using $PSScriptRoot\hash.bat
            & "$PSScriptRoot\hash.bat" "$rest"
            # Get the hash
            $hash = Get-Content -Path "$env:TEMP\hash.txt"
            # Finally, start compiling the echo command
            Add-Content -Path $OutputAsmFile -Value "
; echo ${rest}
sub rsp, 40
mov ecx, -11
call GetStdHandle
mov rbx, rax
mov rcx, rbx
lea rdx, [rel ${hash}]
mov r8d, ${hash}_len
xor r9, r9
mov qword [rsp+32], 0
call WriteConsoleA
add rsp, 40
            "

            Write-Host "Compiled echo command successfully" -ForegroundColor Green
        }
    } elseif ($is_label -eq $true -and $command -ne '') {
        # Add label to assembly file
        Add-Content -Path $OutputAsmFile -Value "
${command}:
        "
    }
}
$prepend = "; Compiled from $InputFile by the `"compiler.bat`" compiler.`r`n; This is NOT the original source code.`r`n"
$content = Get-Content $OutputAsmFile -Raw
$prepend + $content | Set-Content $OutputAsmFile
