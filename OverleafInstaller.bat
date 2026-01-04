@echo off
echo ============================================
echo Installing Overleaf via WSL2
echo ============================================
echo.
echo Note: This requires:
echo  - Docker Desktop running
echo  - WSL2 installed and enabled
echo  - Docker Desktop WSL2 integration enabled
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

echo WSL2 detected. Checking Docker integration...
echo.

REM Check if Docker is accessible from WSL
wsl bash -c "docker ps" >nul 2>&1
if errorlevel 1 (
    echo ============================================
    echo ERROR: Docker is not accessible from WSL2!
    echo ============================================
    echo.
    echo Please enable Docker Desktop WSL2 integration:
    echo 1. Open Docker Desktop
    echo 2. Go to Settings ^(gear icon^)
    echo 3. Go to Resources ^> WSL Integration
    echo 4. Enable integration with your WSL distribution
    echo 5. Click "Apply ^& Restart"
    echo.
    echo Also make sure:
    echo - Docker Desktop is running ^(check system tray^)
    echo - "Use the WSL 2 based engine" is enabled in General settings
    echo.
    echo After fixing this, run the script again.
    pause
    exit /b 1
)

echo Docker integration confirmed!
echo.

REM Clean up any existing installation in WSL
echo Cleaning up any previous installation...
echo Stopping any running containers...
wsl bash -c "cd ~/toolkit 2>/dev/null && bin/stop 2>/dev/null || true"
timeout /t 5
echo Removing old files (this may take a moment)...
wsl bash -c "cd ~ && sudo rm -rf toolkit overleaf-toolkit 2>/dev/null || rm -rf toolkit overleaf-toolkit 2>/dev/null || true"

echo.
echo Cloning Overleaf Toolkit in WSL...
wsl bash -c "cd ~ && git clone https://github.com/overleaf/toolkit.git"
if errorlevel 1 (
    echo Error: Git clone failed in WSL.
    pause
    exit /b 1
)

echo.
echo Installing TeX Live base packages inside WSL...
wsl bash -c "sudo apt update && sudo apt install -y texlive texlive-latex-recommended texlive-latex-extra texlive-fonts-recommended texlive-fonts-extra texlive-science texlive-pictures texlive-lang-german lmodern fontconfig"

echo.
echo Initializing Overleaf...
wsl bash -c "cd ~/toolkit && bin/init"
if errorlevel 1 (
    echo Error: Initialization failed.
    echo Make sure Docker Desktop is running and WSL2 integration enabled!
    pause
    exit /b 1
)

echo.
echo Starting Overleaf containers...
echo This will download Docker images (may take 10-20 minutes on first run)
echo.
wsl bash -c "cd ~/toolkit && bin/up -d"

echo.
echo Waiting for containers to start and become healthy...
echo This may take 1-2 minutes...
echo.

REM Wait for containers to be ready with retry logic
set RETRY=0
set MAX_RETRIES=12

:WAIT_LOOP
set /a RETRY+=1
timeout /t 10 >nul

echo Checking if containers are ready (attempt %RETRY%/%MAX_RETRIES%)...
wsl bash -c "docker ps --filter name=sharelatex --filter status=running --format {{.Names}}" | findstr sharelatex >nul
if errorlevel 1 (
    if %RETRY% LSS %MAX_RETRIES% (
        echo Containers not ready yet, waiting...
        goto WAIT_LOOP
    ) else (
        echo.
        echo ERROR: Containers failed to start properly!
        echo Please check Docker Desktop and try running the script again.
        pause
        exit /b 1
    )
)

echo Containers are running!
echo.

REM Additional wait for services to be fully ready
echo Waiting for Overleaf services to fully initialize...
timeout /t 20

echo.
echo ============================================
echo Installing Essential LaTeX Packages in Container
echo ============================================
echo This includes: stix, fontaxes, lmodern, biblatex, biblatex-ieee, and more
echo This may take 5-10 minutes...
echo.

REM Find the container name
for /f "tokens=*" %%i in ('wsl bash -c "docker ps --filter name=sharelatex --format {{.Names}} | head -n 1"') do set CONTAINER=%%i

if "%CONTAINER%"=="" (
    echo ERROR: Could not find Overleaf container!
    echo The installation completed but package installation will be skipped.
    goto SKIP_PACKAGES
)

echo Found container: %CONTAINER%
echo Installing packages via tlmgr...
echo.

REM Install essential TeX packages inside the container
wsl bash -c "docker exec %CONTAINER% bash -c 'tlmgr update --self && \
tlmgr install stix fontaxes collection-fontsrecommended collection-latexextra etoolbox float geometry csquotes biblatex biblatex-ieee xkeyval tabularx lastpage icomma fancyhdr opensans keyval kvoptions pdftexcmds ltxcmds iftex babel babel-german expl3 l3backend xparse figureversions && \
fmtutil-sys --all'"

if errorlevel 1 (
    echo.
    echo WARNING: tlmgr package installation failed!
    echo Overleaf is running but some LaTeX packages may be missing.
    goto SKIP_PACKAGES
)

echo.
echo ============================================
echo LaTeX Packages Installed Successfully!
echo ============================================
echo.
echo Restarting Overleaf to apply changes...
wsl bash -c "cd ~/toolkit && bin/stop"
timeout /t 5
wsl bash -c "cd ~/toolkit && bin/up -d"
echo Waiting for restart to complete...
timeout /t 15

:SKIP_PACKAGES
echo.
echo ============================================
echo Overleaf Installation Complete!
echo ============================================
echo.
echo Access Overleaf at: http://localhost/launchpad
echo.
echo Installed LaTeX packages include:
echo  - stix
echo  - fontaxes
echo  - collection-latexextra
echo  - collection-fontsrecommended
echo  - biblatex, biblatex-ieee
echo  - etoolbox, float, geometry, csquotes
echo  - xkeyval, tabularx, lastpage, icomma
echo  - fancyhdr, opensans, keyval, kvoptions
echo  - pdftexcmds, ltxcmds, iftex, babel, babel-german
echo  - expl3, l3backend, xparse, figureversions
echo.
echo Useful commands:
echo  - Stop Overleaf:  wsl bash -c "cd ~/toolkit && bin/stop"
echo  - Start Overleaf: wsl bash -c "cd ~/toolkit && bin/up"
echo  - View logs:      wsl bash -c "cd ~/toolkit && bin/logs"
echo.
echo ============================================
pause
