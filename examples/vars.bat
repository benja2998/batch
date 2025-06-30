@echo off

goto main

:main

set foo=1
goto main3

:main2

set foo=2
echo %foo%
exit /b 0

:main3

set foo=3
goto main2