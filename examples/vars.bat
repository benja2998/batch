@echo off

goto main

:main

set foo=1
goto main3

:main2

set foo=2
echo %foo%
set exitcode=0
exit /b %exitcode%

:main3

set foo=3
goto main2