@echo off

echo Jump to main
goto main

:main
echo Set foo to 1
set foo=1
echo Jump to label3
goto label3

:label1
echo At label1 - jump to label5
goto label5

:label2
echo At label2 - jump to label7
goto label7

:label3
echo At label3 - set foo to 3
set foo=3
echo Jump to label4
goto label4

:label4
echo At label4 - jump to label2
goto label2

:label5
echo At label5 - set exitcode to 0
set exitcode=0
echo Jump to label6
goto label6

:label6
echo At label6 - jump to label8
goto label8

:label7
echo At label7 - set command
set "command=winget.exe"
echo Jump to label9
goto label9

:label8
echo At label8 - launch winget
echo Launching %command%
cmd.exe /c %command%
echo Jump to label10
goto label10

:label9
echo At label9 - show foo value
echo Foo is %foo%
echo Jump to label1
goto label1

:label10
echo At label10 - benchmark complete
exit /b %exitcode%