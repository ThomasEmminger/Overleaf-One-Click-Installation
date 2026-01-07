@echo off
echo ============================================
echo Installing Overleaf via WSL2 (Full TeX Live)
echo ============================================
echo.
echo Note: This requires:
echo  - Docker Desktop running
echo  - WSL2 installed and enabled
echo  - Docker Desktop WSL2 integration enabled
echo.
pause

REM ------------------------------
REM Check if WSL is available
REM ------------------------------
wsl --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: WSL2 is not installed!
    echo Please install WSL2 first by running in PowerShell:
    echo   wsl --install
    pause
    exit /b 1
)
echo WSL2 detected. Checking Docker integration...
echo.

REM ------------------------------
REM Check Docker in WSL
REM ------------------------------
wsl bash -c "docker ps" >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker is not accessible from WSL2!
    echo Please enable Docker Desktop WSL2 integration and ensure Docker is running.
    pause
    exit /b 1
)
echo Docker integration confirmed!
echo.

REM ------------------------------
REM Clean up any existing installation
REM ------------------------------
echo Cleaning up previous installation...
wsl bash -c "cd ~/toolkit 2>/dev/null && bin/stop 2>/dev/null || true"
timeout /t 5
wsl bash -c "cd ~ && sudo rm -rf toolkit overleaf-toolkit 2>/dev/null || rm -rf toolkit overleaf-toolkit 2>/dev/null || true"
echo.

echo Cloning Overleaf Toolkit in WSL...
wsl bash -c "cd ~ && git clone https://github.com/overleaf/toolkit.git"
if errorlevel 1 (
    echo ERROR: Git clone failed in WSL.
    pause
    exit /b 1
)
echo.

echo Initializing Overleaf...
wsl bash -c "cd ~/toolkit && bin/init"
if errorlevel 1 (
    echo ERROR: Initialization failed.
    pause
    exit /b 1
)
echo.

echo Configuring for Full TeX Live...
wsl bash -c "cd ~/toolkit && sed -i 's/OVERLEAF_IMAGE_VERSION=.*/OVERLEAF_IMAGE_VERSION=5.2/' config/overleaf.rc"
wsl bash -c "cd ~/toolkit && echo 'TEXLIVE_IMAGE=texlive/texlive:latest' >> config/overleaf.rc"
echo.

echo Starting Overleaf containers (may take 10-20 minutes)...
wsl bash -c "cd ~/toolkit && bin/up -d"
echo.

echo Waiting for containers to start...
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
        echo ERROR: Containers failed to start properly!
        pause
        exit /b 1
    )
)
echo Containers are running!
timeout /t 20
echo.

REM ------------------------------
REM Update tlmgr and Install Full TeX Live
REM ------------------------------
echo Updating TeX Live package manager...
wsl bash -c "cd ~/toolkit && docker exec sharelatex tlmgr update --self --all"
if errorlevel 1 (
    echo WARNING: tlmgr update had issues, but continuing...
)
echo.

echo Installing Full TeX Live packages (this may take 10-20 minutes)...
echo Please be patient, this downloads several GB of data...
wsl bash -c "cd ~/toolkit && docker exec sharelatex tlmgr install scheme-full"
if errorlevel 1 (
    echo.
    echo WARNING: Full scheme installation failed or was interrupted.
    echo Trying to install essential collections instead...
    wsl bash -c "cd ~/toolkit && docker exec sharelatex tlmgr install collection-latex collection-latexrecommended collection-latexextra collection-fontsrecommended collection-fontsextra"
)
echo.

echo Verifying float.sty installation...
wsl bash -c "docker exec sharelatex kpsewhich float.sty" >nul 2>&1
if errorlevel 1 (
    echo WARNING: float.sty not found. You may need to install packages manually.
) else (
    echo Success! LaTeX packages installed correctly.
)
echo.

REM ------------------------------
REM Finished installation
REM ------------------------------
echo ============================================
echo Overleaf Installation Complete!
echo ============================================
echo Access Overleaf at: http://localhost/launchpad
start http://localhost/launchpad
pause
