@echo off
set "ROOT=%~dp0..\"
"%ROOT%\tools\converter.exe" "%ROOT%\src_c\raygui.h" "%ROOT%\sdk_freebasic\inc\raygui.bi"
pause