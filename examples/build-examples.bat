@echo off
echo Searching for and compiling .bas files...
echo -------------------------------------

REM The FOR /R loop searches recursively through the current folder and subfolders
for /R %%f in (*.bas) do (
    echo Compiling: %%f
    fbc "%%f"
)

echo -------------------------------------
echo Process finished.
pause