@echo off
setlocal enabledelayedexpansion

:: =========================================================================
:: CONFIGURACION
:: =========================================================================
set "ROOT=%~dp0..\"
set "SRC=%ROOT%examples\raygui.bas"
set "FB_INC=%ROOT%sdk_freebasic\inc"

:: Librerias Staticas SDK
set "FB_LIB_32=%ROOT%sdk_freebasic\lib\x86"
set "FB_LIB_64=%ROOT%sdk_freebasic\lib\x64"

:: Librerias C Originales (para rellenar SDK si falta)
set "C_LIB_32=%ROOT%lib_c\x86"
set "C_LIB_64=%ROOT%lib_c\x64"

:: DLLs de sistema (Solo raylib.dll si usaras version dinamica, 
:: pero aqui estamos FULL ESTATICO, asi que no copiamos nada extra de raygui)
:: Si raylib es estatico, no necesitamos copiar DLLs, el EXE es standalone.

set "OUT_DIR_32=%ROOT%bin\examples\x86"
set "OUT_DIR_64=%ROOT%bin\examples\x64"

if not exist "%OUT_DIR_32%" mkdir "%OUT_DIR_32%"
if not exist "%OUT_DIR_64%" mkdir "%OUT_DIR_64%"

:: =========================================================================
:: PREPARACION SDK
:: =========================================================================
:: Copiar libraylib.a si falta
if exist "%C_LIB_64%\libraylib.a" if not exist "%FB_LIB_64%\libraylib.a" copy /Y "%C_LIB_64%\libraylib.a" "%FB_LIB_64%\" >nul
if exist "%C_LIB_32%\libraylib.a" if not exist "%FB_LIB_32%\libraylib.a" copy /Y "%C_LIB_32%\libraylib.a" "%FB_LIB_32%\" >nul

:: =========================================================================
:: COMPILACION X64
:: =========================================================================
echo.
echo [x64] Compilando ejemplo (Estatico)...
call fbc64 "%SRC%" -x "%OUT_DIR_64%\raygui.exe" -i "%FB_INC%" -p "%FB_LIB_64%"

if %ERRORLEVEL% EQU 0 (
    echo [OK] x64 Compilado.
) else (
    echo [ERROR] Fallo x64.
)

:: =========================================================================
:: COMPILACION X86
:: =========================================================================
echo.
echo [x86] Compilando ejemplo (Estatico)...
call fbc32 "%SRC%" -x "%OUT_DIR_32%\raygui.exe" -i "%FB_INC%" -p "%FB_LIB_32%"

if %ERRORLEVEL% EQU 0 (
    echo [OK] x86 Compilado.
) else (
    echo [ERROR] Fallo x86.
)

echo.
echo [INFO] Proceso finalizado.
pause