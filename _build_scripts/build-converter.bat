@echo off
setlocal
:: Definimos la raiz del proyecto (un nivel arriba de esta carpeta)
set "ROOT=%~dp0..\"

echo [INFO] Compilando converter tool...
:: Ejecutamos fbc desde la raiz para que encuentre el archivo
pushd "%ROOT%"
fbc32 "tools\converter.bas"
popd

if exist "%ROOT%\tools\converter.exe" (
    echo [OK] Converter compilado correctamente.
) else (
    echo [ERROR] No se pudo compilar el converter.
)
pause