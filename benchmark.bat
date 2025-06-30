@echo off
setlocal enabledelayedexpansion

rem Get test selection
set /p "testnum=Enter test number (1-3): "

if %testnum%==1 (
   set "testfile=hello"
) else if %testnum%==2 (
   set "testfile=labels"
) else if %testnum%==3 (
   set "testfile=vars"
) else (
   echo Invalid test number
   exit /b 1
)

make test%testnum%
cls

echo Benchmarking %testfile% (10 iterations)...
echo ---------------------------

rem Run original 10 times and get average
for /f "tokens=*" %%a in ('powershell -command "$times=@(); 1..10|foreach{$times+=(measure-command {.\\examples\\%testfile%.bat}).TotalMilliseconds}; $avg=$times|measure-object -average|select-object -expand average; [math]::round($avg,3).tostring('0.000', [globalization.cultureinfo]::invariantculture)"') do (
    set "original_avg=%%a"
)

rem Run compiled 10 times and get average
for /f "tokens=*" %%a in ('powershell -command "$times=@(); 1..10|foreach{$times+=(measure-command {.\\test.exe}).TotalMilliseconds}; $avg=$times|measure-object -average|select-object -expand average; [math]::round($avg,3).tostring('0.000', [globalization.cultureinfo]::invariantculture)"') do (
    set "compiled_avg=%%a"
)

rem Calculate speed ratio
for /f "tokens=*" %%a in ('powershell -command "[math]::round([double]%original_avg%/[double]%compiled_avg%, 1).tostring([globalization.cultureinfo]::invariantculture)"') do (
    set "speed_ratio=%%a"
)

echo Original Average: %original_avg% ms
echo Compiled Average: %compiled_avg% ms
echo.
if %compiled_avg% lss %original_avg% (
    echo The compiled exe is %speed_ratio% times faster
) else (
    echo The compiled exe is %speed_ratio% times slower
)
echo ---------------------------