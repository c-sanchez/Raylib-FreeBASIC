@echo off
setlocal enabledelayedexpansion

:: =========================================================================
:: CONFIGURACION
:: =========================================================================
set "ROOT=%~dp0..\"
set "SRC_H=%ROOT%src_c\raygui.h"
set "TEMP_C=%ROOT%raygui_build_temp.c"
set "C_INCLUDE=%ROOT%src_c"

:: Rutas Librerias C (Donde estan los gcc)
set "C_LIB_32=%ROOT%lib_c\x86"
set "C_LIB_64=%ROOT%lib_c\x64"

:: Rutas Salida FreeBASIC (Donde van los .a)
set "FB_LIB_32=%ROOT%sdk_freebasic\lib\x86"
set "FB_LIB_64=%ROOT%sdk_freebasic\lib\x64"

:: 1. Crear directorios
if not exist "%FB_LIB_32%" mkdir "%FB_LIB_32%"
if not exist "%FB_LIB_64%" mkdir "%FB_LIB_64%"

:: 2. Crear fuente temporal
echo [INFO] Creando fuente temporal...
copy /Y "%SRC_H%" "%TEMP_C%" >nul

:: =========================================================================
:: COMPILACION X64 (ESTATICA)
:: =========================================================================
echo.
echo [x64] Creando libraygui.a Estatica...

:: --- LIMPIEZA IMPORTANTE ---
if exist "%FB_LIB_64%\libraygui.a" (
    echo [CLEAN] Borrando libreria antigua x64...
    del "%FB_LIB_64%\libraygui.a"
)
:: ---------------------------

:: 1. Compilar a Objeto (.o)
call gcc64 -c "%TEMP_C%" -o "%ROOT%raygui64.o" ^
    -I"%C_INCLUDE%" ^
    -DRAYGUI_IMPLEMENTATION ^
    -DRAYGUI_STATIC

if !ERRORLEVEL! EQU 0 (
    :: 2. Empaquetar
    echo [x64] Empaquetando libreria...
    call ar64 rcs "%FB_LIB_64%\libraygui.a" "%ROOT%raygui64.o"
    
    if !ERRORLEVEL! EQU 0 (
        echo [OK] libraygui.a x64 creado correctamente.
    ) else (
        echo [ERROR] Fallo al crear el archivo .a con ar.
    )
) else (
    echo [ERROR] Fallo la compilacion GCC x64.
)

:: Limpiar objeto
if exist "%ROOT%raygui64.o" del "%ROOT%raygui64.o"

:: =========================================================================
:: COMPILACION X86 (ESTATICA)
:: =========================================================================
echo.
echo [x86] Creando libraygui.a Estatica...

:: --- LIMPIEZA IMPORTANTE ---
if exist "%FB_LIB_32%\libraygui.a" (
    echo [CLEAN] Borrando libreria antigua x86...
    del "%FB_LIB_32%\libraygui.a"
)
:: ---------------------------

:: 1. Compilar a Objeto (.o)
call gcc32 -c "%TEMP_C%" -o "%ROOT%raygui32.o" ^
    -I"%C_INCLUDE%" ^
    -DRAYGUI_IMPLEMENTATION ^
    -DRAYGUI_STATIC

if !ERRORLEVEL! EQU 0 (
    :: 2. Empaquetar
    echo [x86] Empaquetando libreria...
    call ar32 rcs "%FB_LIB_32%\libraygui.a" "%ROOT%raygui32.o"
    
    if !ERRORLEVEL! EQU 0 (
        echo [OK] libraygui.a x86 creado correctamente.
    ) else (
        echo [ERROR] Fallo al crear el archivo .a con ar.
    )
) else (
    echo [ERROR] Fallo la compilacion GCC x86.
)

:: Limpiar
if exist "%ROOT%raygui32.o" del "%ROOT%raygui32.o"
if exist "%TEMP_C%" del "%TEMP_C%"

echo.
echo [INFO] Proceso finalizado.
pause