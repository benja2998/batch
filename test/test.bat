@echo off

rem This is a remark
:: This is a broken label
echo Hello, world!
goto type_license

:type_license

type ..\LICENSE
pause >nul
exit /b