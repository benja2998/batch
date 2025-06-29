@echo off

rem This is a remark
:: This is a broken label
:: echo !hello!
echo Hello, world!
goto this_will_run

:this_wont_run
echo This won't run

:this_will_run
echo This will run