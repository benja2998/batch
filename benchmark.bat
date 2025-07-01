@echo off
setlocal enabledelayedexpansion

rem Get test selection
set /p "testnum=Enter test number (1-4): "

if %testnum%==1 (
   set "testfile=hello"
) else if %testnum%==2 (
   set "testfile=labels"
) else if %testnum%==3 (
   set "testfile=vars"
) else if %testnum%==4 (
   set "testfile=invalid_command"
) else (
   echo Invalid test number
   exit /b 1
)

set /p "iter=Enter number of iterations: "

if "%iter%"=="" (
    echo No iterations specified, defaulting to 10.
    set "iter=10"
)

make test%testnum%
cls

echo Benchmarking %testfile% (%iter% iterations)...
echo ---------------------------

rem Run original %iter% times and get average
for /f "tokens=*" %%a in ('powershell -command "$times=@(); 1..%iter%|foreach{$times+=(measure-command {.\\examples\\%testfile%.bat}).TotalMilliseconds}; $avg=$times|measure-object -average|select-object -expand average; [math]::round($avg,3).tostring('0.000', [globalization.cultureinfo]::invariantculture)"') do (
    set "original_avg=%%a"
)

rem Run compiled %iter% times and get average
for /f "tokens=*" %%a in ('powershell -command "$times=@(); 1..%iter%|foreach{$times+=(measure-command {.\\test.exe}).TotalMilliseconds}; $avg=$times|measure-object -average|select-object -expand average; [math]::round($avg,3).tostring('0.000', [globalization.cultureinfo]::invariantculture)"') do (
    set "compiled_avg=%%a"
)

rem Remove .* from average values

for /f "tokens=1 delims=." %%a in ("%original_avg%") do (
    set "original_avg=%%a"
)

for /f "tokens=1 delims=." %%a in ("%compiled_avg%") do (
    set "compiled_avg=%%a"
)

rem Calculate speed ratio
for /f "tokens=*" %%a in ('powershell -command "[math]::round([double]%original_avg%/[double]%compiled_avg%, 1).tostring([globalization.cultureinfo]::invariantculture)"') do (
    set "speed_ratio=%%a"
)

echo Original Average: %original_avg% ms
echo Compiled Average: %compiled_avg% ms
echo.
echo The compiled version is %speed_ratio% times the speed of the original script
echo ---------------------------