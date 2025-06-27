@echo off

rem This is a remark
:: This is a broken label

echo Hello world!
echo.

:done

echo Almost done!
goto finally_done

:finally_done

echo Done!
exit /b