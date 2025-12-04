@echo off
REM ========================================================================
REM Lab System Installation Script
REM Automatically installs all required software for the lab environment
REM Must be run as Administrator
REM ========================================================================

setlocal EnableDelayedExpansion

REM Check for Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo ========================================================================
    echo ERROR: This script must be run as Administrator!
    echo ========================================================================
    echo.
    echo Please right-click on this script and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

REM Display header
cls
echo ========================================================================
echo              LAB SYSTEM INSTALLATION SCRIPT
echo ========================================================================
echo.
echo This script will install all required software for the lab environment.
echo Installation will be fully automated.
echo.
echo Please ensure you have a stable internet connection.
echo.
echo ========================================================================
echo.

REM Log file setup
set LOG_FILE=%~dp0installation-log_%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%.txt
set LOG_FILE=%LOG_FILE: =0%
echo Installation started at %date% %time% > "%LOG_FILE%"

echo Installation log will be saved to:
echo %LOG_FILE%
echo.
timeout /t 3 /nobreak >nul

REM ========================================================================
REM Step 1: Install Chocolatey Package Manager
REM ========================================================================
echo [1/13] Checking Chocolatey Package Manager...
echo [1/13] Checking Chocolatey Package Manager... >> "%LOG_FILE%"

where choco >nul 2>&1
if %errorLevel% neq 0 (
    echo Chocolatey not found. Installing Chocolatey...
    echo Chocolatey not found. Installing... >> "%LOG_FILE%"

    REM Install Chocolatey
    echo Installing Chocolatey Package Manager...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))" >> "%LOG_FILE%" 2>&1

    REM Refresh environment
    call :RefreshPath

    REM Verify installation
    timeout /t 5 /nobreak >nul
    where choco >nul 2>&1
    if !errorLevel! neq 0 (
        echo ERROR: Failed to install Chocolatey. Please install manually.
        echo ERROR: Chocolatey installation failed >> "%LOG_FILE%"
        pause
        exit /b 1
    )
    echo Chocolatey installed successfully!
    echo Chocolatey installed successfully >> "%LOG_FILE%"
) else (
    for /f "tokens=*" %%a in ('choco --version') do set CHOCO_VER=%%a
    echo Chocolatey already installed: !CHOCO_VER!
    echo Chocolatey already installed: !CHOCO_VER! >> "%LOG_FILE%"
)
echo.

REM ========================================================================
REM Step 2: Install Python 3.12
REM ========================================================================
echo [2/13] Installing Python 3.12...
echo [2/13] Installing Python 3.12... >> "%LOG_FILE%"
choco install python312 -y --force >> "%LOG_FILE%" 2>&1
if %errorLevel% equ 0 (
    echo Python 3.12 installed successfully!
    echo Python 3.12 installed successfully >> "%LOG_FILE%"
) else (
    echo Python 3.12 installation completed with code: %errorLevel%
    echo Python 3.12 installation exit code: %errorLevel% >> "%LOG_FILE%"
)
call :RefreshPath
echo.

REM ========================================================================
REM Step 3: Install Node.js
REM ========================================================================
echo [3/13] Installing Node.js...
echo [3/13] Installing Node.js... >> "%LOG_FILE%"
choco install nodejs -y --force >> "%LOG_FILE%" 2>&1
if %errorLevel% equ 0 (
    echo Node.js installed successfully!
    echo Node.js installed successfully >> "%LOG_FILE%"
) else (
    echo Node.js installation completed with code: %errorLevel%
    echo Node.js installation exit code: %errorLevel% >> "%LOG_FILE%"
)
call :RefreshPath
echo.

REM ========================================================================
REM Step 4: Install Git
REM ========================================================================
echo [4/13] Installing Git...
echo [4/13] Installing Git... >> "%LOG_FILE%"
choco install git -y --force >> "%LOG_FILE%" 2>&1
if %errorLevel% equ 0 (
    echo Git installed successfully!
    echo Git installed successfully >> "%LOG_FILE%"
) else (
    echo Git installation completed with code: %errorLevel%
    echo Git installation exit code: %errorLevel% >> "%LOG_FILE%"
)
call :RefreshPath
echo.

REM ========================================================================
REM Step 5: Install GitHub CLI
REM ========================================================================
echo [5/13] Installing GitHub CLI...
echo [5/13] Installing GitHub CLI... >> "%LOG_FILE%"
choco install gh -y --force >> "%LOG_FILE%" 2>&1
if %errorLevel% equ 0 (
    echo GitHub CLI installed successfully!
    echo GitHub CLI installed successfully >> "%LOG_FILE%"
) else (
    echo GitHub CLI installation completed with code: %errorLevel%
    echo GitHub CLI installation exit code: %errorLevel% >> "%LOG_FILE%"
)
call :RefreshPath
echo.

REM ========================================================================
REM Step 6: Install Docker Desktop
REM ========================================================================
echo [6/13] Installing Docker Desktop...
echo [6/13] Installing Docker Desktop... >> "%LOG_FILE%"
choco install docker-desktop -y --force >> "%LOG_FILE%" 2>&1
if %errorLevel% equ 0 (
    echo Docker Desktop installed successfully!
    echo Docker Desktop installed successfully >> "%LOG_FILE%"
) else (
    echo Docker Desktop installation completed with code: %errorLevel%
    echo Docker Desktop installation exit code: %errorLevel% >> "%LOG_FILE%"
)
call :RefreshPath
echo.

REM ========================================================================
REM Step 7: Install kubectl
REM ========================================================================
echo [7/13] Installing kubectl...
echo [7/13] Installing kubectl... >> "%LOG_FILE%"
choco install kubernetes-cli -y --force >> "%LOG_FILE%" 2>&1
if %errorLevel% equ 0 (
    echo kubectl installed successfully!
    echo kubectl installed successfully >> "%LOG_FILE%"
) else (
    echo kubectl installation completed with code: %errorLevel%
    echo kubectl installation exit code: %errorLevel% >> "%LOG_FILE%"
)
call :RefreshPath
echo.

REM ========================================================================
REM Step 8: Install Visual Studio Code
REM ========================================================================
echo [8/13] Installing Visual Studio Code...
echo [8/13] Installing Visual Studio Code... >> "%LOG_FILE%"
choco install vscode -y --force >> "%LOG_FILE%" 2>&1
if %errorLevel% equ 0 (
    echo Visual Studio Code installed successfully!
    echo Visual Studio Code installed successfully >> "%LOG_FILE%"
) else (
    echo Visual Studio Code installation completed with code: %errorLevel%
    echo Visual Studio Code installation exit code: %errorLevel% >> "%LOG_FILE%"
)
call :RefreshPath
echo.

REM ========================================================================
REM Step 9: Install Google Chrome
REM ========================================================================
echo [9/13] Installing Google Chrome...
echo [9/13] Installing Google Chrome... >> "%LOG_FILE%"
choco install googlechrome -y --force >> "%LOG_FILE%" 2>&1
if %errorLevel% equ 0 (
    echo Google Chrome installed successfully!
    echo Google Chrome installed successfully >> "%LOG_FILE%"
) else (
    echo Google Chrome installation completed with code: %errorLevel%
    echo Google Chrome installation exit code: %errorLevel% >> "%LOG_FILE%"
)
call :RefreshPath
echo.

REM ========================================================================
REM Step 10: Install Multipass
REM ========================================================================
echo [10/13] Installing Multipass...
echo [10/13] Installing Multipass... >> "%LOG_FILE%"
choco install multipass -y --force >> "%LOG_FILE%" 2>&1
if %errorLevel% equ 0 (
    echo Multipass installed successfully!
    echo Multipass installed successfully >> "%LOG_FILE%"
) else (
    echo Multipass installation completed with code: %errorLevel%
    echo Multipass installation exit code: %errorLevel% >> "%LOG_FILE%"
)
call :RefreshPath
echo.

REM ========================================================================
REM Step 11: Install WSL and Ubuntu
REM ========================================================================
echo [11/13] Installing WSL and Ubuntu...
echo [11/13] Installing WSL and Ubuntu... >> "%LOG_FILE%"

REM Check if WSL is already installed
wsl --version >nul 2>&1
if %errorLevel% neq 0 (
    echo Installing WSL...
    wsl --install --no-launch >> "%LOG_FILE%" 2>&1
    echo WSL installation initiated. A restart may be required.
    echo WSL installation initiated >> "%LOG_FILE%"
) else (
    echo WSL already installed.
    echo WSL already installed >> "%LOG_FILE%"
)

REM Install Ubuntu distribution
wsl --list --verbose | findstr "Ubuntu" >nul 2>&1
if %errorLevel% neq 0 (
    echo Installing Ubuntu distribution...
    wsl --install -d Ubuntu --no-launch >> "%LOG_FILE%" 2>&1
    echo Ubuntu distribution installation initiated.
    echo Ubuntu installation initiated >> "%LOG_FILE%"
) else (
    echo Ubuntu distribution already installed.
    echo Ubuntu already installed >> "%LOG_FILE%"
)
echo.

REM ========================================================================
REM Step 12: Refresh PATH and Install UV via pip
REM ========================================================================
echo [12/13] Installing UV Python package manager...
echo [12/13] Installing UV Python package manager... >> "%LOG_FILE%"

REM Refresh environment variables
echo Refreshing PATH environment...
call :RefreshPath

REM Wait a moment for Python to be fully available
timeout /t 3 /nobreak >nul

REM Try to install UV using pip
python --version >nul 2>&1
if %errorLevel% equ 0 (
    echo Installing UV via pip...
    python -m pip install --upgrade pip >> "%LOG_FILE%" 2>&1
    python -m pip install uv >> "%LOG_FILE%" 2>&1
    if !errorLevel! equ 0 (
        echo UV installed successfully via pip!
        echo UV installed successfully >> "%LOG_FILE%"
    ) else (
        echo Warning: UV installation via pip failed. You may need to restart and run: pip install uv
        echo UV installation failed >> "%LOG_FILE%"
    )
) else (
    echo Warning: Python not found in PATH. Please restart your computer and run: pip install uv
    echo Python not found after installation >> "%LOG_FILE%"
)
echo.

REM ========================================================================
REM Step 13: Install VS Code Extensions
REM ========================================================================
echo [13/13] Installing VS Code Extensions...
echo [13/13] Installing VS Code Extensions... >> "%LOG_FILE%"

REM Refresh PATH again to ensure code command is available
call :RefreshPath

REM Wait for VS Code to be available
timeout /t 3 /nobreak >nul

code --version >nul 2>&1
if %errorLevel% equ 0 (
    echo Installing VS Code extensions...

    call :InstallExtension "ms-vscode-remote.remote-containers" "Remote - Containers"
    call :InstallExtension "github.copilot" "GitHub Copilot"
    call :InstallExtension "github.copilot-chat" "GitHub Copilot Chat"
    call :InstallExtension "ms-toolsai.jupyter" "Jupyter"
    call :InstallExtension "ms-toolsai.vscode-jupyter-cell-tags" "Jupyter Cell Tags"
    call :InstallExtension "ms-toolsai.jupyter-keymap" "Jupyter Keymap"
    call :InstallExtension "ms-toolsai.jupyter-renderers" "Jupyter Renderers"
    call :InstallExtension "ms-toolsai.vscode-jupyter-slideshow" "Jupyter Slideshow"
    call :InstallExtension "shd101wyy.markdown-preview-enhanced" "Markdown Preview Enhanced"
    call :InstallExtension "ms-python.vscode-pylance" "Pylance"
    call :InstallExtension "ms-python.python" "Python"
    call :InstallExtension "ms-python.debugpy" "Python Debugger"
    call :InstallExtension "mechatroner.rainbow-csv" "Rainbow CSV"
    call :InstallExtension "qwtel.sqlite-viewer" "SQLite Viewer"
    call :InstallExtension "ms-vscode-remote.remote-wsl" "WSL"
    call :InstallExtension "redhat.vscode-yaml" "YAML"

    echo All VS Code extensions installation completed!
    echo VS Code extensions installation completed >> "%LOG_FILE%"
) else (
    echo Warning: VS Code command-line not available. Please restart and run extensions installation manually.
    echo VS Code CLI not available >> "%LOG_FILE%"
)
echo.

REM ========================================================================
REM Step 14: Enable Kubernetes in Docker Desktop
REM ========================================================================
echo.
echo ========================================================================
echo Configuring Docker Desktop Kubernetes...
echo ========================================================================
echo Docker Desktop Kubernetes configuration... >> "%LOG_FILE%"
echo.
echo Note: Kubernetes in Docker Desktop requires manual enablement:
echo 1. Open Docker Desktop
echo 2. Go to Settings ^> Kubernetes
echo 3. Check "Enable Kubernetes"
echo 4. Click "Apply & Restart"
echo.
echo Attempting to configure via settings file...

REM Check if Docker Desktop settings file exists
set DOCKER_SETTINGS=%APPDATA%\Docker\settings.json
if exist "%DOCKER_SETTINGS%" (
    echo Docker settings found. Creating backup...
    copy "%DOCKER_SETTINGS%" "%DOCKER_SETTINGS%.backup" >nul 2>&1

    REM Use PowerShell to modify JSON
    powershell -Command "& {$json = Get-Content '%DOCKER_SETTINGS%' | ConvertFrom-Json; $json | Add-Member -NotePropertyName 'kubernetesEnabled' -NotePropertyValue $true -Force; $json | ConvertTo-Json -Depth 32 | Set-Content '%DOCKER_SETTINGS%'}" >> "%LOG_FILE%" 2>&1

    if !errorLevel! equ 0 (
        echo Kubernetes enabled in Docker Desktop settings.
        echo Please restart Docker Desktop for changes to take effect.
        echo Kubernetes enabled in settings >> "%LOG_FILE%"
    ) else (
        echo Automatic configuration failed. Please enable manually.
        echo Kubernetes auto-config failed >> "%LOG_FILE%"
    )
) else (
    echo Docker Desktop settings not found. Please configure manually after first launch.
    echo Docker settings file not found >> "%LOG_FILE%"
)
echo.

REM ========================================================================
REM Installation Complete
REM ========================================================================
echo ========================================================================
echo                  INSTALLATION COMPLETED
echo ========================================================================
echo.
echo All software installations have been completed!
echo.
echo IMPORTANT NEXT STEPS:
echo.
echo 1. RESTART YOUR COMPUTER to ensure all PATH changes take effect
echo.
echo 2. After restart, configure Docker Desktop:
echo    - Launch Docker Desktop
echo    - Go to Settings ^> Kubernetes
echo    - Enable Kubernetes if not already enabled
echo    - Apply and restart Docker Desktop
echo.
echo 3. Complete WSL setup ^(if first-time installation^):
echo    - Open PowerShell or Command Prompt
echo    - Run: wsl --install
echo    - Create Ubuntu user account when prompted
echo.
echo 4. Verify UV installation after restart:
echo    - Run: uv --version
echo    - If not found, run: pip install uv
echo.
echo 5. Run the installation-check.ps1 script to verify all installations:
echo    - powershell -ExecutionPolicy Bypass -File installation-check.ps1
echo.
echo Installation log saved to: %LOG_FILE%
echo.
echo Installation completed at %date% %time% >> "%LOG_FILE%"
echo ========================================================================
echo.
pause
exit /b 0

REM ========================================================================
REM Helper Functions
REM ========================================================================

:InstallExtension
set EXT_ID=%~1
set EXT_NAME=%~2
echo Installing %EXT_NAME%...
code --install-extension %EXT_ID% --force >> "%LOG_FILE%" 2>&1
if %errorLevel% equ 0 (
    echo   [OK] %EXT_NAME%
) else (
    echo   [WARN] %EXT_NAME% installation returned code %errorLevel%
)
echo Extension %EXT_ID% exit code: %errorLevel% >> "%LOG_FILE%"
goto :eof

:RefreshPath
REM Refresh PATH environment variable from registry
for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYS_PATH=%%b"
for /f "tokens=2*" %%a in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "USER_PATH=%%b"
set "PATH=%SYS_PATH%;%USER_PATH%"
goto :eof
