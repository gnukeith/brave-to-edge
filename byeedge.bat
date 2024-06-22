@echo off

:: This script will install Chocolatey, install Brave, and then remove Microsoft Edge.

:: Install Chocolatey
echo *** Installing Chocolatey ***
@powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
if %ERRORLEVEL% NEQ 0 (
    echo Failed to install Chocolatey.
    pause
    exit /B 1
)
echo .....Done.

:: Install Brave Browser
echo *** Installing Brave Browser ***
choco install brave -y
if %ERRORLEVEL% NEQ 0 (
    echo Failed to install Brave Browser.
    pause
    exit /B 1
)
echo .....Done.

:: Kill Microsoft Edge process
echo *** Killing Microsoft Edge process ***
taskkill /F /IM msedge.exe >nul 2>&1

:: Navigate to the user's Desktop directory
CD %HOMEDRIVE%%HOMEPATH%\Desktop
echo %CD%

:: Remove Microsoft Edge directories
echo *** Removing Microsoft Edge ***
call :killdir "C:\Windows\SystemApps\Microsoft.MicrosoftEdge*"
call :killdir "C:\Program Files (x86)\Microsoft\Edge"
call :killdir "C:\Program Files (x86)\Microsoft\EdgeUpdate"
call :killdir "C:\Program Files (x86)\Microsoft\EdgeCore"
call :killdir "C:\Program Files (x86)\Microsoft\EdgeWebView"

:: Edit the registry to remove Edge settings
call :editreg

:: Remove Microsoft Edge shortcuts
echo *** Removing Shortcuts ***
call :delshortcut "C:\Users\Public\Desktop\Microsoft Edge.lnk"
call :delshortcut "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk"
call :delshortcut "%APPDATA%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Edge.lnk"
echo done
pause
exit

:killdir
:: Subroutine to remove directories
echo|set /p=Removing dir %1
if exist %1 (
    takeown /a /r /d Y /f %1 > NUL
    icacls %1 /grant administrators:f /t > NUL
    rd /s /q %1 > NUL
    if exist %1 (
        echo .....Failed.
    ) else (
        echo .....Deleted.
    )
) else (
    echo .....Not found.
)
exit /B 0

:editreg
:: Subroutine to edit the registry to remove Edge-related settings
echo|set /p=Editing registry
echo Windows Registry Editor Version 5.00 > RemoveEdge.reg
echo. >> RemoveEdge.reg
echo [HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge] >> RemoveEdge.reg
echo "AllowPrelaunch"=dword:00000001 >> RemoveEdge.reg
echo "DoNotUpdateToEdgeWithChromium"=dword:00000001 >> RemoveEdge.reg
echo. >> RemoveEdge.reg
echo [-HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{9459C573-B17A-45AE-9F64-1857B5D58CEE}] >> RemoveEdge.reg

regedit /s RemoveEdge.reg > NUL
del RemoveEdge.reg
echo .....Done.
exit /B 0

:delshortcut
:: Subroutine to delete shortcuts
if exist "%1" (
    del "%1"
    echo Deleted shortcut %1
) else (
    echo Shortcut %1 not found
)
exit /B 0
