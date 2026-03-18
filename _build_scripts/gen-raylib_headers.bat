@echo off
setlocal
:: Definir raiz
set "ROOT=%~dp0..\"
set "TOOL=%ROOT%tools\converter.exe"

:: Directorios Entrada (C) y Salida (FB)
set "INC_C=%ROOT%src_c"
set "INC_FB=%ROOT%sdk_freebasic\inc"

:: Asegurar que existe destino
if not exist "%INC_FB%" mkdir "%INC_FB%"

echo [INFO] Convirtiendo headers de C a FreeBASIC...

echo ... raylib.h
"%TOOL%" "%INC_C%\raylib.h" "%INC_FB%\raylib.bi"

echo ... raymath.h
"%TOOL%" "%INC_C%\raymath.h" "%INC_FB%\raymath.bi"

echo ... rlgl.h
"%TOOL%" "%INC_C%\rlgl.h" "%INC_FB%\rlgl.bi"

echo ... raygui.h
"%TOOL%" "%INC_C%\raygui.h" "%INC_FB%\raygui.bi"

echo.
echo [OK] Conversion terminada. Revise la carpeta sdk_freebasic/inc
pause