@echo off

echo Hello world!
echo Hello world! > hello.txt
echo Hello world! >> hello.txt
goto skip_exitcode_69
exit /b 69
:skip_exitcode_69
rem Exit with code 0 instead of 69
:: Testing this comment style
exit /b 0