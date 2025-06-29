@echo off

:label1

echo label1
rem Jump to label 3
goto label3

:label2

echo label2
rem Exit the batch file
exit /b 0

:label3

echo label3
rem Jump to label 2
goto label2