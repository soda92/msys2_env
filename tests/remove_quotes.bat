@echo off

:removequotes
FOR /F "delims=" %%A IN ('echo %%%1%%') DO set %1=%%~A
goto :eof

@REM https://g.co/gemini/share/2910892361e7
