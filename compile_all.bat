@echo off
setlocal enabledelayedexpansion

REM === CONFIG ===
REM Full path to gsc-tool.exe (NO quotes here)
set GSC_TOOL=E:\GSC\gsc-tool.exe

REM Target game and system
set GAME=iw8
set SYSTEM=pc

REM Folder to scan (default is current folder)
set "SRC_FOLDER=%~1"
if "%SRC_FOLDER%"=="" set "SRC_FOLDER=."

echo Compiling all .gsc files in "%SRC_FOLDER%"...
echo.

REM Loop through all .gsc files recursively
for /r "%SRC_FOLDER%" %%F in (*.gsc) do (
    echo -----------------------------------------
    echo Compiling: "%%F"
    "%GSC_TOOL%" -m comp -g %GAME% -s %SYSTEM% "%%F"
)

echo -----------------------------------------
echo All done!
pause
