@echo off
REM ========================================================================
REM Lab System Installation Script
REM Automatically installs all required software for the lab environment
REM Must be run as Administrator
REM ========================================================================

setlocal EnableDelayedExpansion

REM Progress tracking variables
set TOTAL_STEPS=15
set CURRENT_STEP=0

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
ping 127.0.0.1 -n 4 >nul 2>&1

REM ========================================================================
REM Step 1: Install Chocolatey Package Manager
REM ========================================================================
set /a CURRENT_STEP+=1
call :DrawProgressBar %CURRENT_STEP% %TOTAL_STEPS% "Installing Chocolatey Package Manager"

echo [1/15] Checking Chocolatey Package Manager...
echo [1/15] Checking Chocolatey Package Manager... >> "%LOG_FILE%"

where choco >nul 2>&1
if %errorLevel% neq 0 (
    echo Chocolatey not found. Installing Chocolatey...
    echo Chocolatey not found. Installing... >> "%LOG_FILE%"

    REM Install Chocolatey
    echo Installing Chocolatey Package Manager...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))" >> "%LOG_FILE%" 2>&1

    REM Refresh environment
    call :RefreshPath

    REM Verify installation (wait 5 seconds using ping instead of timeout for compatibility)
    ping 127.0.0.1 -n 6 >nul 2>&1
    where choco >nul 2>&1
    if !errorLevel! neq 0 (
        echo ERROR: Failed to install Chocolatey. Please install manually.
        echo ERROR: Chocolatey installation failed >> "%LOG_FILE%"
        echo.
        echo Manual installation instructions:
        echo 1. Visit: https://chocolatey.org/install
        echo 2. Run PowerShell as Administrator
        echo 3. Execute the installation command from the website
        echo.
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
set /a CURRENT_STEP+=1
call :DrawProgressBar %CURRENT_STEP% %TOTAL_STEPS% "Installing Python 3.12"

echo [2/15] Checking Python 3.12...
echo [2/15] Checking Python 3.12... >> "%LOG_FILE%"

python --version 2>nul | findstr "Python 3.12" >nul 2>&1
if %errorLevel% equ 0 (
    echo Python 3.12 already installed. Skipping...
    echo Python 3.12 already installed >> "%LOG_FILE%"
) else (
    echo Installing Python 3.12...
    choco install python312 -y >> "%LOG_FILE%" 2>&1
    if !errorLevel! equ 0 (
        echo Python 3.12 installed successfully!
        echo Python 3.12 installed successfully >> "%LOG_FILE%"
    ) else (
        echo Python 3.12 installation completed with code: !errorLevel!
        echo Python 3.12 installation exit code: !errorLevel! >> "%LOG_FILE%"
    )
)
call :RefreshPath
echo.

REM ========================================================================
REM Step 3: Install Node.js
REM ========================================================================
set /a CURRENT_STEP+=1
call :DrawProgressBar %CURRENT_STEP% %TOTAL_STEPS% "Installing Node.js"

echo [3/15] Checking Node.js...
echo [3/15] Checking Node.js... >> "%LOG_FILE%"

node --version >nul 2>&1
if %errorLevel% equ 0 (
    for /f "tokens=*" %%a in ('node --version') do set NODE_VER=%%a
    echo Node.js already installed: !NODE_VER!. Skipping...
    echo Node.js already installed: !NODE_VER! >> "%LOG_FILE%"
) else (
    echo Installing Node.js...
    choco install nodejs -y >> "%LOG_FILE%" 2>&1
    if !errorLevel! equ 0 (
        echo Node.js installed successfully!
        echo Node.js installed successfully >> "%LOG_FILE%"
    ) else (
        echo Node.js installation completed with code: !errorLevel!
        echo Node.js installation exit code: !errorLevel! >> "%LOG_FILE%"
    )
)
call :RefreshPath
echo.

REM ========================================================================
REM Step 4: Install Git
REM ========================================================================
set /a CURRENT_STEP+=1
call :DrawProgressBar %CURRENT_STEP% %TOTAL_STEPS% "Installing Git"

echo [4/15] Checking Git...
echo [4/15] Checking Git... >> "%LOG_FILE%"

git --version >nul 2>&1
if %errorLevel% equ 0 (
    for /f "tokens=*" %%a in ('git --version') do set GIT_VER=%%a
    echo Git already installed: !GIT_VER!. Skipping...
    echo Git already installed: !GIT_VER! >> "%LOG_FILE%"
) else (
    echo Installing Git...
    choco install git -y >> "%LOG_FILE%" 2>&1
    if !errorLevel! equ 0 (
        echo Git installed successfully!
        echo Git installed successfully >> "%LOG_FILE%"
    ) else (
        echo Git installation completed with code: !errorLevel!
        echo Git installation exit code: !errorLevel! >> "%LOG_FILE%"
    )
)
call :RefreshPath
echo.

REM ========================================================================
REM Step 5: Install GitHub CLI
REM ========================================================================
set /a CURRENT_STEP+=1
call :DrawProgressBar %CURRENT_STEP% %TOTAL_STEPS% "Installing GitHub CLI"

echo [5/15] Checking GitHub CLI...
echo [5/15] Checking GitHub CLI... >> "%LOG_FILE%"

gh --version >nul 2>&1
if %errorLevel% equ 0 (
    echo GitHub CLI already installed. Skipping...
    echo GitHub CLI already installed >> "%LOG_FILE%"
) else (
    echo Installing GitHub CLI...
    choco install gh -y >> "%LOG_FILE%" 2>&1
    if !errorLevel! equ 0 (
        echo GitHub CLI installed successfully!
        echo GitHub CLI installed successfully >> "%LOG_FILE%"
    ) else (
        echo GitHub CLI installation completed with code: !errorLevel!
        echo GitHub CLI installation exit code: !errorLevel! >> "%LOG_FILE%"
    )
)
call :RefreshPath
echo.

REM ========================================================================
REM Step 6: Install Docker Desktop
REM ========================================================================
set /a CURRENT_STEP+=1
call :DrawProgressBar %CURRENT_STEP% %TOTAL_STEPS% "Installing Docker Desktop"

echo [6/15] Checking Docker Desktop...
echo [6/15] Checking Docker Desktop... >> "%LOG_FILE%"

docker --version >nul 2>&1
if %errorLevel% equ 0 (
    for /f "tokens=*" %%a in ('docker --version') do set DOCKER_VER=%%a
    echo Docker Desktop already installed: !DOCKER_VER!. Skipping...
    echo Docker Desktop already installed >> "%LOG_FILE%"
) else (
    echo Installing Docker Desktop...
    choco install docker-desktop -y >> "%LOG_FILE%" 2>&1
    if !errorLevel! equ 0 (
        echo Docker Desktop installed successfully!
        echo Docker Desktop installed successfully >> "%LOG_FILE%"
    ) else (
        echo Docker Desktop installation completed with code: !errorLevel!
        echo Docker Desktop installation exit code: !errorLevel! >> "%LOG_FILE%"
    )
)
call :RefreshPath
echo.

REM ========================================================================
REM Step 7: Install kubectl
REM ========================================================================
set /a CURRENT_STEP+=1
call :DrawProgressBar %CURRENT_STEP% %TOTAL_STEPS% "Installing kubectl"

echo [7/15] Checking kubectl...
echo [7/15] Checking kubectl... >> "%LOG_FILE%"

kubectl version --client >nul 2>&1
if %errorLevel% equ 0 (
    echo kubectl already installed. Skipping...
    echo kubectl already installed >> "%LOG_FILE%"
) else (
    echo Installing kubectl...
    choco install kubernetes-cli -y >> "%LOG_FILE%" 2>&1
    if !errorLevel! equ 0 (
        echo kubectl installed successfully!
        echo kubectl installed successfully >> "%LOG_FILE%"
    ) else (
        echo kubectl installation completed with code: !errorLevel!
        echo kubectl installation exit code: !errorLevel! >> "%LOG_FILE%"
    )
)
call :RefreshPath
echo.

REM ========================================================================
REM Step 8: Install Visual Studio Code
REM ========================================================================
set /a CURRENT_STEP+=1
call :DrawProgressBar %CURRENT_STEP% %TOTAL_STEPS% "Installing Visual Studio Code"

echo [8/15] Checking Visual Studio Code...
echo [8/15] Checking Visual Studio Code... >> "%LOG_FILE%"

code --version >nul 2>&1
if %errorLevel% equ 0 (
    echo Visual Studio Code already installed. Skipping...
    echo Visual Studio Code already installed >> "%LOG_FILE%"
) else (
    echo Installing Visual Studio Code...
    choco install vscode -y >> "%LOG_FILE%" 2>&1
    if !errorLevel! equ 0 (
        echo Visual Studio Code installed successfully!
        echo Visual Studio Code installed successfully >> "%LOG_FILE%"
    ) else (
        echo Visual Studio Code installation completed with code: !errorLevel!
        echo Visual Studio Code installation exit code: !errorLevel! >> "%LOG_FILE%"
    )
)
call :RefreshPath
echo.

REM ========================================================================
REM Step 9: Install Google Chrome
REM ========================================================================
set /a CURRENT_STEP+=1
call :DrawProgressBar %CURRENT_STEP% %TOTAL_STEPS% "Installing Google Chrome"

echo [9/15] Checking Google Chrome...
echo [9/15] Checking Google Chrome... >> "%LOG_FILE%"

if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" (
    echo Google Chrome already installed. Skipping...
    echo Google Chrome already installed >> "%LOG_FILE%"
) else if exist "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" (
    echo Google Chrome already installed. Skipping...
    echo Google Chrome already installed >> "%LOG_FILE%"
) else if exist "%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe" (
    echo Google Chrome already installed. Skipping...
    echo Google Chrome already installed >> "%LOG_FILE%"
) else (
    echo Installing Google Chrome...
    choco install googlechrome -y >> "%LOG_FILE%" 2>&1
    if !errorLevel! equ 0 (
        echo Google Chrome installed successfully!
        echo Google Chrome installed successfully >> "%LOG_FILE%"
    ) else (
        echo Google Chrome installation completed with code: !errorLevel!
        echo Google Chrome installation exit code: !errorLevel! >> "%LOG_FILE%"
    )
)
call :RefreshPath
echo.

REM ========================================================================
REM Step 10: Install Fira Code Font
REM ========================================================================
set /a CURRENT_STEP+=1
call :DrawProgressBar %CURRENT_STEP% %TOTAL_STEPS% "Installing Fira Code Font"

echo [10/15] Installing Fira Code Font...
echo [10/15] Installing Fira Code Font... >> "%LOG_FILE%"
choco install firacode -y --force >> "%LOG_FILE%" 2>&1
if %errorLevel% equ 0 (
    echo Fira Code Font installed successfully!
    echo Fira Code Font installed successfully >> "%LOG_FILE%"
) else (
    echo Fira Code Font installation completed with code: %errorLevel%
    echo Fira Code Font installation exit code: %errorLevel% >> "%LOG_FILE%"
)
call :RefreshPath
echo.

REM ========================================================================
REM Step 11: Install Windows Terminal
REM ========================================================================
set /a CURRENT_STEP+=1
call :DrawProgressBar %CURRENT_STEP% %TOTAL_STEPS% "Installing Windows Terminal"

echo [11/15] Installing Windows Terminal...
echo [11/15] Installing Windows Terminal... >> "%LOG_FILE%"
choco install microsoft-windows-terminal -y --force >> "%LOG_FILE%" 2>&1
if %errorLevel% equ 0 (
    echo Windows Terminal installed successfully!
    echo Windows Terminal installed successfully >> "%LOG_FILE%"
) else (
    echo Windows Terminal installation completed with code: %errorLevel%
    echo Windows Terminal installation exit code: %errorLevel% >> "%LOG_FILE%"
)
call :RefreshPath
echo.

REM ========================================================================
REM Step 12: Install Multipass
REM ========================================================================
set /a CURRENT_STEP+=1
call :DrawProgressBar %CURRENT_STEP% %TOTAL_STEPS% "Installing Multipass"

echo [12/15] Checking Multipass...
echo [12/15] Checking Multipass... >> "%LOG_FILE%"

multipass version >nul 2>&1
if %errorLevel% equ 0 (
    echo Multipass already installed. Skipping...
    echo Multipass already installed >> "%LOG_FILE%"
) else (
    echo Installing Multipass...
    choco install multipass -y >> "%LOG_FILE%" 2>&1
    if !errorLevel! equ 0 (
        echo Multipass installed successfully!
        echo Multipass installed successfully >> "%LOG_FILE%"
    ) else (
        echo Multipass installation completed with code: !errorLevel!
        echo Multipass installation exit code: !errorLevel! >> "%LOG_FILE%"
    )
)
call :RefreshPath
echo.

REM ========================================================================
REM Step 13: Install WSL and Ubuntu
REM ========================================================================
set /a CURRENT_STEP+=1
call :DrawProgressBar %CURRENT_STEP% %TOTAL_STEPS% "Installing WSL and Ubuntu"

echo [13/15] Installing WSL and Ubuntu...
echo [13/15] Installing WSL and Ubuntu... >> "%LOG_FILE%"

REM Enable WSL and Virtual Machine Platform features
echo Enabling WSL features...
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart >> "%LOG_FILE%" 2>&1
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart >> "%LOG_FILE%" 2>&1

if %errorLevel% equ 0 (
    echo WSL features enabled successfully.
    echo WSL features will be available after system restart.
    echo WSL features enabled >> "%LOG_FILE%"
) else (
    echo WSL feature enablement completed with code: %errorLevel%
    echo WSL feature enablement may require manual verification.
    echo WSL feature enablement exit code: %errorLevel% >> "%LOG_FILE%"
)

REM Download and install WSL2 kernel update
echo Downloading WSL2 kernel update...
powershell -Command "Invoke-WebRequest -Uri 'https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi' -OutFile '%TEMP%\wsl_update_x64.msi'" >> "%LOG_FILE%" 2>&1

if exist "%TEMP%\wsl_update_x64.msi" (
    echo Installing WSL2 kernel update...
    msiexec /i "%TEMP%\wsl_update_x64.msi" /quiet /norestart >> "%LOG_FILE%" 2>&1
    echo WSL2 kernel update installed.
    echo WSL2 kernel update installed >> "%LOG_FILE%"
    del "%TEMP%\wsl_update_x64.msi" >nul 2>&1
) else (
    echo WSL2 kernel download failed. Will be available via Windows Update.
    echo WSL2 kernel download failed >> "%LOG_FILE%"
)

REM Set WSL2 as default
echo Setting WSL2 as default version...
wsl --set-default-version 2 >> "%LOG_FILE%" 2>&1

REM Update WSL to latest version
echo Updating WSL to latest version...
wsl --update >> "%LOG_FILE%" 2>&1
if %errorLevel% equ 0 (
    echo WSL updated successfully.
    echo WSL updated successfully >> "%LOG_FILE%"
) else (
    echo WSL update will be available after system restart.
    echo WSL update pending restart >> "%LOG_FILE%"
)

echo.
echo NOTE: WSL and Ubuntu installation requires a system restart.
echo After restart, you can install Ubuntu by running:
echo   wsl --install -d Ubuntu
echo Or use Microsoft Store to install Ubuntu.
echo.
echo WSL installation completed (restart required) >> "%LOG_FILE%"
echo.

REM ========================================================================
REM Step 14: Refresh PATH and Install UV via pip
REM ========================================================================
set /a CURRENT_STEP+=1
call :DrawProgressBar %CURRENT_STEP% %TOTAL_STEPS% "Installing UV Python Package Manager"

echo [14/15] Installing UV Python package manager...
echo [14/15] Installing UV Python package manager... >> "%LOG_FILE%"

REM Refresh environment variables
echo Refreshing PATH environment...
call :RefreshPath

REM Wait a moment for Python to be fully available
ping 127.0.0.1 -n 4 >nul 2>&1

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
REM Step 15: Install VS Code Extensions
REM ========================================================================
set /a CURRENT_STEP+=1
call :DrawProgressBar %CURRENT_STEP% %TOTAL_STEPS% "Installing VS Code Extensions"

echo [15/15] Installing VS Code Extensions...
echo [15/15] Installing VS Code Extensions... >> "%LOG_FILE%"

REM Refresh PATH again to ensure code command is available
call :RefreshPath

REM Wait for VS Code to be available
ping 127.0.0.1 -n 4 >nul 2>&1

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
REM Post-Installation Configuration
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
REM Configure Windows Terminal Settings
REM ========================================================================
echo.
echo ========================================================================
echo Configuring Windows Terminal...
echo ========================================================================
echo Windows Terminal configuration... >> "%LOG_FILE%"
echo.

REM Windows Terminal settings path
set WT_SETTINGS=%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json

if exist "%WT_SETTINGS%" (
    echo Windows Terminal settings found. Creating backup...
    copy "%WT_SETTINGS%" "%WT_SETTINGS%.backup" >nul 2>&1

    REM Configure Windows Terminal with PowerShell
    powershell -NoProfile -ExecutionPolicy Bypass -Command "& { $settingsPath = '%WT_SETTINGS%'; if (Test-Path $settingsPath) { $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json; if (-not $settings.profiles.defaults) { $settings.profiles | Add-Member -NotePropertyName 'defaults' -NotePropertyValue @{} -Force }; $settings.profiles.defaults | Add-Member -NotePropertyName 'fontFace' -NotePropertyValue 'Fira Code' -Force; $settings.profiles.defaults | Add-Member -NotePropertyName 'fontSize' -NotePropertyValue 12 -Force; $cmdGuid = ($settings.profiles.list | Where-Object { $_.name -eq 'Command Prompt' -or $_.commandline -like '*cmd.exe*' }).guid; if ($cmdGuid) { $settings | Add-Member -NotePropertyName 'defaultProfile' -NotePropertyValue $cmdGuid -Force }; $settings | ConvertTo-Json -Depth 32 | Set-Content $settingsPath } }" >> "%LOG_FILE%" 2>&1

    if !errorLevel! equ 0 (
        echo Windows Terminal configured successfully!
        echo  - Default profile: Command Prompt
        echo  - Font: Fira Code
        echo  - Font size: 12
        echo Windows Terminal configured >> "%LOG_FILE%"
    ) else (
        echo Windows Terminal auto-configuration failed.
        echo Please configure manually:
        echo  1. Open Windows Terminal
        echo  2. Press Ctrl+, to open settings
        echo  3. Set default profile to Command Prompt
        echo  4. In Appearance, set font to Fira Code and size to 12
        echo Windows Terminal config failed >> "%LOG_FILE%"
    )
) else (
    echo Windows Terminal settings not found.
    echo Launch Windows Terminal once, then re-run this script or configure manually.
    echo Windows Terminal settings file not found >> "%LOG_FILE%"
)
echo.

REM ========================================================================
REM Installation Complete
REM ========================================================================
echo.
call :DrawProgressBar %TOTAL_STEPS% %TOTAL_STEPS% "Installation Complete!"
echo.
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
echo 2. Launch Windows Terminal to verify configuration:
echo    - Default profile should be Command Prompt
echo    - Font should be Fira Code, size 12
echo    - If not configured, press Ctrl+, and adjust manually
echo.
echo 3. After restart, configure Docker Desktop:
echo    - Launch Docker Desktop
echo    - Go to Settings ^> Kubernetes
echo    - Enable Kubernetes if not already enabled
echo    - Apply and restart Docker Desktop
echo.
echo 4. Complete WSL setup ^(if first-time installation^):
echo    - Open PowerShell or Command Prompt
echo    - Run: wsl --install
echo    - Create Ubuntu user account when prompted
echo.
echo 5. Verify UV installation after restart:
echo    - Run: uv --version
echo    - If not found, run: pip install uv
echo.
echo 6. Run the installation-check.ps1 script to verify all installations:
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

:DrawProgressBar
set STEP=%~1
set TOTAL=%~2
set LABEL=%~3

REM Calculate percentage
set /a PERCENT=(%STEP% * 100) / %TOTAL%

REM Calculate filled and empty sections (40 character width)
set /a FILLED=(%STEP% * 40) / %TOTAL%
set /a EMPTY=40 - FILLED

REM Build progress bar string using ASCII characters
set BAR=
for /l %%i in (1,1,%FILLED%) do set BAR=!BAR!#
for /l %%i in (1,1,%EMPTY%) do set BAR=!BAR!-

REM Display progress bar
echo.
echo ================================================================
echo Overall Progress: [!BAR!] !PERCENT!%%
echo Step %STEP% of %TOTAL%: %LABEL%
echo ================================================================
echo.
goto :eof

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
