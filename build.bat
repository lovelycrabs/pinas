@echo off
setlocal

set "ROOT=%~dp0"
set "DIST=%ROOT%dist"
set "PACKAGE=%DIST%\pinas-package"
set "DISPLAY=%PACKAGE%\pinas-display"
set "ZIP=%DIST%\pinas.zip"

if not exist "%DIST%" mkdir "%DIST%"

if exist "%PACKAGE%" rmdir /s /q "%PACKAGE%"
mkdir "%PACKAGE%"

echo Copying project files...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Copy-Item '%ROOT%overlays','%ROOT%scripts','%ROOT%utils' '%PACKAGE%' -Recurse -Force; Copy-Item '%ROOT%install.sh','%ROOT%README.md' '%PACKAGE%' -Force"
if errorlevel 1 exit /b 1

echo Cloning pinas-display...
git clone https://github.com/lovelycrabs/pinas-display.git "%DISPLAY%"
if errorlevel 1 exit /b 1
if exist "%ZIP%" del /q "%ZIP%"
tar.exe -a -c -f "%ZIP%" -C "%DIST%" pinas-package
if errorlevel 1 exit /b 1
copy /y "%ROOT%doc\readme.txt" "%DIST%\readme.txt" >nul
if errorlevel 1 exit /b 1

echo Build completed: %ZIP%
echo Installation guide copied: %DIST%\\readme.txt
endlocal
