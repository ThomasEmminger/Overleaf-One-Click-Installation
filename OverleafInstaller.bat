@echo off
echo ============================================
echo Installing Overleaf via WSL2
echo ============================================
echo.
echo Note: This requires:
echo  - Docker Desktop running
echo  - WSL2 installed and enabled
echo.
pause

REM Check if WSL is available
wsl --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: WSL2 is not installed!
    echo.
    echo Please install WSL2 first by running in PowerShell:
    echo   wsl --install
    echo.
    echo Then restart your computer and run this script again.
    pause
    exit /b 1
)

echo WSL2 detected. Proceeding with installation...
echo.

REM Clean up any existing installation in WSL
echo Cleaning up any previous installation...
wsl bash -c "cd ~ && rm -rf toolkit overleaf-toolkit"

echo.
echo Cloning Overleaf Toolkit in WSL...
wsl bash -c "cd ~ && git clone https://github.com/overleaf/toolkit.git"
if errorlevel 1 (
    echo Error: Git clone failed in WSL.
    pause
    exit /b 1
)

echo.
echo Initializing Overleaf...
wsl bash -c "cd ~/toolkit && bin/init"
if errorlevel 1 (
    echo Error: Initialization failed.
    echo Make sure Docker Desktop is running and WSL2 integration is enabled!
    pause
    exit /b 1
)

echo.
echo Starting Overleaf containers...
echo This will download Docker images (may take 10-20 minutes on first run)
echo.
wsl bash -c "cd ~/toolkit && bin/up"

echo.
echo ============================================
echo Overleaf installation complete!
echo.
echo Access Overleaf at: http://localhost/launchpad
echo.
echo To stop Overleaf later, run:
echo   wsl bash -c "cd ~/toolkit && bin/stop"
echo.
echo To start it again, run:
echo   wsl bash -c "cd ~/toolkit && bin/up"
echo ============================================
pause