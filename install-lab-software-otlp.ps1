#Requires -RunAsAdministrator
<#
.SYNOPSIS
    OTLP / Observability Lab System Installation Script (PowerShell Core)
.DESCRIPTION
    Installs everything from install-lab-software.ps1 PLUS the software needed for an
    OpenTelemetry (OTLP) session with open-source backends:
      - Temurin JDK 21, Maven, OpenTelemetry Java agent
      - jq, curl, Grafana k6
      - Extra VS Code extensions (Java, Maven, Docker, REST Client)
      - Pre-pulled Docker images: OTel Collector (contrib), telemetrygen, Prometheus,
        Grafana, Loki, Tempo, Jaeger (versions pinned in otlp-images.psd1)
    Images are pulled only - students start the containers during the lab.
    Must be run as Administrator with PowerShell Core (pwsh).
.PARAMETER SkipChecks
    Reinstall / re-pull everything, even when already present.
.PARAMETER ImagesOnly
    Skip all software installation; only start Docker and pull the lab images.
    Use this after the first run + reboot, once Docker Desktop is up.
.EXAMPLE
    pwsh -File .\install-lab-software-otlp.ps1
.EXAMPLE
    pwsh -File .\install-lab-software-otlp.ps1 -ImagesOnly
.NOTES
    File Name      : install-lab-software-otlp.ps1
    Prerequisite   : PowerShell Core 7.0+ and Administrator privileges
                     otlp-images.psd1 in the same folder
    Copyright 2025 - iomegak12
#>

[CmdletBinding()]
param(
    [switch]$SkipChecks,
    [switch]$ImagesOnly
)

# Script configuration
$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

# Progress tracking
$script:TotalSteps = 24
$script:CurrentStep = 0

# Log file setup
$LogFile = Join-Path $PSScriptRoot "installation-log_otlp_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# Pinned OTLP lab versions
$OtlpConfigFile = Join-Path $PSScriptRoot "otlp-images.psd1"

# Docker image pull results (filled by Install-ObservabilityImages)
$script:ImageStatus = @()

#region Helper Functions

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string]$Level = 'Info'
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $logMessage

    switch ($Level) {
        'Success' { Write-Host $Message -ForegroundColor Green }
        'Warning' { Write-Host $Message -ForegroundColor Yellow }
        'Error'   { Write-Host $Message -ForegroundColor Red }
        default   { Write-Host $Message -ForegroundColor White }
    }
}

function Show-ProgressBar {
    param(
        [int]$Step,
        [int]$Total,
        [string]$Label
    )

    $script:CurrentStep = $Step
    $percent = [math]::Round(($Step / $Total) * 100)
    $filled = [math]::Floor(($Step / $Total) * 40)
    $empty = 40 - $filled

    $bar = ('#' * $filled) + ('-' * $empty)

    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "Overall Progress: [$bar] $percent%" -ForegroundColor Cyan
    Write-Host "Step $Step of ${Total}: $Label" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Test-CommandExists {
    param([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

function Install-Software {
    param(
        [string]$Name,
        [string]$PackageName,
        [scriptblock]$CheckInstalled,
        [string]$StepLabel
    )

    $script:CurrentStep++
    Show-ProgressBar -Step $script:CurrentStep -Total $script:TotalSteps -Label $StepLabel

    Write-Host "[$script:CurrentStep/$script:TotalSteps] Checking $Name..." -ForegroundColor Yellow
    Write-Log "Checking $Name..."

    if (-not $SkipChecks -and (& $CheckInstalled)) {
        Write-Log "$Name already installed. Skipping..." -Level Success
        return $true
    }

    Write-Host "Installing $Name..." -ForegroundColor Cyan
    Write-Log "Installing $Name..."

    try {
        $result = choco install $PackageName -y 2>&1
        Add-Content -Path $LogFile -Value $result

        if ($LASTEXITCODE -eq 0) {
            Write-Log "$Name installed successfully!" -Level Success
            return $true
        } else {
            Write-Log "$Name installation completed with exit code: $LASTEXITCODE" -Level Warning
            return $false
        }
    }
    catch {
        Write-Log "Error installing ${Name}: $_" -Level Error
        return $false
    }
    finally {
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                    [System.Environment]::GetEnvironmentVariable("Path", "User")
    }
}

function Test-DockerEngine {
    if (-not (Test-CommandExists 'docker')) {
        return $false
    }
    docker info 2>&1 | Out-Null
    return ($LASTEXITCODE -eq 0)
}

function Wait-DockerEngine {
    param([int]$TimeoutSeconds = 180)

    $script:CurrentStep++
    Show-ProgressBar -Step $script:CurrentStep -Total $script:TotalSteps -Label "Starting Docker Engine"

    Write-Host "[$script:CurrentStep/$script:TotalSteps] Checking Docker Engine..." -ForegroundColor Yellow
    Write-Log "Checking Docker Engine..."

    # Refresh PATH in case Docker Desktop was installed in this session
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path", "User")

    if (Test-DockerEngine) {
        Write-Log "Docker Engine is running" -Level Success
        return $true
    }

    $dockerDesktop = Join-Path $env:ProgramFiles "Docker\Docker\Docker Desktop.exe"
    if (-not (Test-Path $dockerDesktop)) {
        Write-Log "Docker Desktop not found at $dockerDesktop" -Level Warning
        return $false
    }

    Write-Host "Starting Docker Desktop (waiting up to $TimeoutSeconds seconds)..." -ForegroundColor Cyan
    Write-Log "Starting Docker Desktop..."
    Start-Process -FilePath $dockerDesktop

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 5
        Write-Host "." -NoNewline -ForegroundColor Gray
        if (Test-DockerEngine) {
            Write-Host ""
            Write-Log "Docker Engine is running" -Level Success
            return $true
        }
    }

    Write-Host ""
    Write-Log "Docker Engine did not become ready within $TimeoutSeconds seconds" -Level Warning
    return $false
}

function Install-ObservabilityImages {
    param(
        [array]$Images,
        [bool]$DockerReady
    )

    $script:CurrentStep++
    Show-ProgressBar -Step $script:CurrentStep -Total $script:TotalSteps -Label "Pulling Observability Docker Images"

    Write-Host "[$script:CurrentStep/$script:TotalSteps] Pulling observability Docker images..." -ForegroundColor Yellow
    Write-Log "Pulling observability Docker images..."

    foreach ($image in $Images) {
        $status = 'MISSING'

        if ($DockerReady) {
            docker image inspect $image.Ref 2>&1 | Out-Null
            $present = ($LASTEXITCODE -eq 0)

            if (-not $SkipChecks -and $present) {
                Write-Host "    [OK] $($image.Ref) (already present)" -ForegroundColor Green
                $status = 'OK'
            } else {
                Write-Host "  Pulling $($image.Ref)..." -ForegroundColor Gray
                docker pull $image.Ref 2>&1 | Out-File -FilePath $LogFile -Append
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "    [OK] $($image.Ref)" -ForegroundColor Green
                    $status = 'OK'
                } else {
                    Write-Host "    [WARN] $($image.Ref) (exit code: $LASTEXITCODE)" -ForegroundColor Yellow
                }
            }
        }

        Write-Log "Image $($image.Ref): $status"
        $script:ImageStatus += [pscustomobject]@{
            Name   = $image.Name
            Ref    = $image.Ref
            Ports  = $image.Ports
            Status = $status
        }
    }

    $missing = @($script:ImageStatus | Where-Object { $_.Status -ne 'OK' }).Count
    if (-not $DockerReady) {
        Write-Log "Docker Engine not running - images not pulled" -Level Warning
        Write-Host "After restart, launch Docker Desktop and run:" -ForegroundColor Yellow
        Write-Host "  pwsh -File install-lab-software-otlp.ps1 -ImagesOnly" -ForegroundColor Gray
    } elseif ($missing -gt 0) {
        Write-Log "$missing image(s) failed to pull. Re-run with -ImagesOnly." -Level Warning
    } else {
        Write-Log "All observability images available" -Level Success
    }

    Write-Host ""
}

function Show-ImageSummary {
    Write-Host "OBSERVABILITY IMAGES:" -ForegroundColor Yellow
    Write-Host ""
    foreach ($image in $script:ImageStatus) {
        $color = if ($image.Status -eq 'OK') { 'Green' } else { 'Red' }
        Write-Host ("  [{0,-7}] " -f $image.Status) -NoNewline -ForegroundColor $color
        Write-Host ("{0,-26} {1}" -f $image.Name, $image.Ref) -ForegroundColor White
        Write-Host ("            port(s): {0}" -f $image.Ports) -ForegroundColor Gray
    }
    Write-Host ""
    if (@($script:ImageStatus | Where-Object { $_.Status -ne 'OK' }).Count -gt 0) {
        Write-Host "  Some images are missing. After Docker Desktop is running, run:" -ForegroundColor Yellow
        Write-Host "    pwsh -File install-lab-software-otlp.ps1 -ImagesOnly" -ForegroundColor Gray
        Write-Host ""
    }
}

#endregion

#region Main Script

# Display header
Clear-Host
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host "   OTLP LAB SYSTEM INSTALLATION SCRIPT (PowerShell Core)" -ForegroundColor Cyan
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host ""

# Check if running PowerShell Core
$isPowerShellCore = $PSVersionTable.PSEdition -eq 'Core'
$psVersion = $PSVersionTable.PSVersion

Write-Host "PowerShell Edition: $($PSVersionTable.PSEdition)" -ForegroundColor Gray
Write-Host "PowerShell Version: $($psVersion.Major).$($psVersion.Minor).$($psVersion.Patch)" -ForegroundColor Gray
Write-Host ""

if (-not $isPowerShellCore) {
    Write-Host "===============================================================" -ForegroundColor Red
    Write-Host "ERROR: PowerShell Core (pwsh) is required!" -ForegroundColor Red
    Write-Host "===============================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "You are currently running: Windows PowerShell $($psVersion.ToString())" -ForegroundColor Yellow
    Write-Host "This script requires: PowerShell Core 7.0 or later (pwsh)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "PowerShell Core is cross-platform and will be installed as part of this process." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "To install PowerShell Core and run this script:" -ForegroundColor White
    Write-Host "  1. Run the install-lab-software.cmd script first, OR" -ForegroundColor Gray
    Write-Host "  2. Install manually from: https://aka.ms/powershell" -ForegroundColor Gray
    Write-Host "  3. Then run this script using: pwsh -File install-lab-software-otlp.ps1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Alternatively, use the batch script for initial installation:" -ForegroundColor Cyan
    Write-Host "  install-lab-software.cmd" -ForegroundColor Gray
    Write-Host ""
    pause
    exit 1
}

if ($psVersion.Major -lt 7) {
    Write-Host "===============================================================" -ForegroundColor Red
    Write-Host "WARNING: PowerShell Core 7.0+ is recommended!" -ForegroundColor Yellow
    Write-Host "===============================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Your current version: $($psVersion.ToString())" -ForegroundColor Yellow
    Write-Host "Recommended version: 7.0 or later" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "The script will continue, but some features may not work correctly." -ForegroundColor Yellow
    Write-Host ""
    $continue = Read-Host "Do you want to continue? (Y/N)"
    if ($continue -ne 'Y' -and $continue -ne 'y') {
        Write-Host "Script cancelled by user." -ForegroundColor Yellow
        exit 1
    }
    Write-Host ""
}

# Load pinned OTLP lab versions
if (-not (Test-Path $OtlpConfigFile)) {
    Write-Host "ERROR: $OtlpConfigFile not found." -ForegroundColor Red
    Write-Host "Keep otlp-images.psd1 in the same folder as this script." -ForegroundColor Yellow
    exit 1
}
$OtlpConfig = Import-PowerShellDataFile -Path $OtlpConfigFile

# Images-only mode: start Docker, pull images, done
if ($ImagesOnly) {
    $script:TotalSteps = 2
    Write-Log "Images-only run started" -Level Info

    $dockerReady = Wait-DockerEngine
    Install-ObservabilityImages -Images $OtlpConfig.Images -DockerReady $dockerReady

    Show-ProgressBar -Step $script:TotalSteps -Total $script:TotalSteps -Label "Image Pull Complete!"
    Show-ImageSummary
    Write-Host "Verify with: .\installation-check.ps1 -Otlp" -ForegroundColor White
    Write-Host "Installation log saved to: $LogFile" -ForegroundColor Cyan
    Write-Host ""
    Write-Log "Images-only run completed" -Level Success
    exit 0
}

Write-Host "This script will install all required software for the OTLP lab environment." -ForegroundColor White
Write-Host "Installation will be fully automated." -ForegroundColor White
Write-Host ""
Write-Host "Please ensure you have a stable internet connection." -ForegroundColor White
Write-Host ""
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Installation log will be saved to:" -ForegroundColor White
Write-Host $LogFile -ForegroundColor Gray
Write-Host ""

Start-Sleep -Seconds 2

Write-Log "Installation started" -Level Info

# Step 1: Install Chocolatey
$script:CurrentStep++
Show-ProgressBar -Step $script:CurrentStep -Total $script:TotalSteps -Label "Installing Chocolatey Package Manager"

Write-Host "[$script:CurrentStep/$script:TotalSteps] Checking Chocolatey Package Manager..." -ForegroundColor Yellow
Write-Log "Checking Chocolatey..."

if (-not (Test-CommandExists 'choco')) {
    Write-Host "Chocolatey not found. Installing..." -ForegroundColor Cyan
    Write-Log "Installing Chocolatey..."

    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

        # Refresh environment
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                    [System.Environment]::GetEnvironmentVariable("Path", "User")

        if (Test-CommandExists 'choco') {
            Write-Log "Chocolatey installed successfully!" -Level Success
        } else {
            Write-Log "Chocolatey installation failed!" -Level Error
            Write-Host "Please install Chocolatey manually from https://chocolatey.org/install" -ForegroundColor Red
            exit 1
        }
    }
    catch {
        Write-Log "Error installing Chocolatey: $_" -Level Error
        exit 1
    }
} else {
    $chocoVersion = choco --version
    Write-Log "Chocolatey already installed: $chocoVersion" -Level Success
}

Write-Host ""

# Step 2: Install Python 3.12
Install-Software `
    -Name "Python 3.12" `
    -PackageName "python312" `
    -CheckInstalled {
        (Test-CommandExists 'python') -and ((python --version 2>&1) -match 'Python 3\.12')
    } `
    -StepLabel "Installing Python 3.12"

# Step 3: Install Node.js
Install-Software `
    -Name "Node.js" `
    -PackageName "nodejs" `
    -CheckInstalled {
        Test-CommandExists 'node'
    } `
    -StepLabel "Installing Node.js"

# Step 4: Install Git
Install-Software `
    -Name "Git" `
    -PackageName "git" `
    -CheckInstalled {
        Test-CommandExists 'git'
    } `
    -StepLabel "Installing Git"

# Step 5: Install GitHub CLI
Install-Software `
    -Name "GitHub CLI" `
    -PackageName "gh" `
    -CheckInstalled {
        Test-CommandExists 'gh'
    } `
    -StepLabel "Installing GitHub CLI"

# Step 6: Install Docker Desktop
Install-Software `
    -Name "Docker Desktop" `
    -PackageName "docker-desktop" `
    -CheckInstalled {
        Test-CommandExists 'docker'
    } `
    -StepLabel "Installing Docker Desktop"

# Step 7: Install kubectl
Install-Software `
    -Name "kubectl" `
    -PackageName "kubernetes-cli" `
    -CheckInstalled {
        Test-CommandExists 'kubectl'
    } `
    -StepLabel "Installing kubectl"

# Step 8: Install Visual Studio Code
Install-Software `
    -Name "Visual Studio Code" `
    -PackageName "vscode" `
    -CheckInstalled {
        (Test-CommandExists 'code') -or
        (Test-Path "$env:ProgramFiles\Microsoft VS Code\Code.exe") -or
        (Test-Path "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe")
    } `
    -StepLabel "Installing Visual Studio Code"

# Step 9: Install PowerShell Core
Install-Software `
    -Name "PowerShell Core" `
    -PackageName "powershell-core" `
    -CheckInstalled {
        Test-CommandExists 'pwsh'
    } `
    -StepLabel "Installing PowerShell Core"

# Step 10: Install Google Chrome
$script:CurrentStep++
Show-ProgressBar -Step $script:CurrentStep -Total $script:TotalSteps -Label "Installing Google Chrome"

Write-Host "[$script:CurrentStep/$script:TotalSteps] Checking Google Chrome..." -ForegroundColor Yellow
Write-Log "Checking Google Chrome..."

$chromePaths = @(
    "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
    "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
)

$chromeInstalled = $chromePaths | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $SkipChecks -and $chromeInstalled) {
    Write-Log "Google Chrome already installed. Skipping..." -Level Success
} else {
    Write-Host "Installing Google Chrome..." -ForegroundColor Cyan
    Write-Log "Installing Google Chrome..."
    choco install googlechrome -y 2>&1 | Out-File -FilePath $LogFile -Append
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Google Chrome installed successfully!" -Level Success
    }
}

Write-Host ""

# Step 11: Install Fira Code Font
Install-Software `
    -Name "Fira Code Font" `
    -PackageName "firacode" `
    -CheckInstalled {
        $false  # Always install fonts to ensure latest version
    } `
    -StepLabel "Installing Fira Code Font"

# Step 12: Install Windows Terminal
Install-Software `
    -Name "Windows Terminal" `
    -PackageName "microsoft-windows-terminal" `
    -CheckInstalled {
        Test-CommandExists 'wt'
    } `
    -StepLabel "Installing Windows Terminal"

# Step 13: Install Multipass
Install-Software `
    -Name "Multipass" `
    -PackageName "multipass" `
    -CheckInstalled {
        Test-CommandExists 'multipass'
    } `
    -StepLabel "Installing Multipass"

# Step 14: Install WSL and Ubuntu
$script:CurrentStep++
Show-ProgressBar -Step $script:CurrentStep -Total $script:TotalSteps -Label "Installing WSL and Ubuntu"

Write-Host "[$script:CurrentStep/$script:TotalSteps] Installing WSL and Ubuntu..." -ForegroundColor Yellow
Write-Log "Installing WSL and Ubuntu..."

try {
    Write-Host "Enabling WSL features..." -ForegroundColor Cyan
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-File -FilePath $LogFile -Append
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-File -FilePath $LogFile -Append
    Write-Log "WSL features enabled successfully"

    # Download WSL2 kernel update
    Write-Host "Downloading WSL2 kernel update..." -ForegroundColor Cyan
    $wslUpdateUrl = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
    $wslUpdatePath = Join-Path $env:TEMP "wsl_update_x64.msi"

    Invoke-WebRequest -Uri $wslUpdateUrl -OutFile $wslUpdatePath -ErrorAction SilentlyContinue

    if (Test-Path $wslUpdatePath) {
        Write-Host "Installing WSL2 kernel update..." -ForegroundColor Cyan
        Start-Process msiexec.exe -ArgumentList "/i `"$wslUpdatePath`" /quiet /norestart" -Wait
        Write-Log "WSL2 kernel update installed"
        Remove-Item $wslUpdatePath -Force -ErrorAction SilentlyContinue
    }

    # Set WSL2 as default and update
    Write-Host "Configuring WSL..." -ForegroundColor Cyan
    wsl --set-default-version 2 2>&1 | Out-File -FilePath $LogFile -Append
    wsl --update 2>&1 | Out-File -FilePath $LogFile -Append

    Write-Log "WSL installation completed (restart required)" -Level Success
    Write-Host ""
    Write-Host "NOTE: WSL requires a system restart." -ForegroundColor Yellow
    Write-Host "After restart, install Ubuntu: wsl --install -d Ubuntu" -ForegroundColor Yellow
    Write-Host ""
}
catch {
    Write-Log "WSL installation error: $_" -Level Warning
}

# Step 15: Install UV Python Package Manager
$script:CurrentStep++
Show-ProgressBar -Step $script:CurrentStep -Total $script:TotalSteps -Label "Installing UV Python Package Manager"

Write-Host "[$script:CurrentStep/$script:TotalSteps] Installing UV Python package manager..." -ForegroundColor Yellow
Write-Log "Installing UV..."

if (Test-CommandExists 'python') {
    try {
        Write-Host "Upgrading pip..." -ForegroundColor Cyan
        python -m pip install --upgrade pip 2>&1 | Out-File -FilePath $LogFile -Append

        Write-Host "Installing UV via pip..." -ForegroundColor Cyan
        python -m pip install uv 2>&1 | Out-File -FilePath $LogFile -Append

        if ($LASTEXITCODE -eq 0) {
            Write-Log "UV installed successfully!" -Level Success
        } else {
            Write-Log "UV installation may require restart" -Level Warning
        }
    }
    catch {
        Write-Log "UV installation error: $_" -Level Warning
    }
} else {
    Write-Log "Python not found. Please restart and run: pip install uv" -Level Warning
}

Write-Host ""

# Step 16: Install VS Code Extensions
$script:CurrentStep++
Show-ProgressBar -Step $script:CurrentStep -Total $script:TotalSteps -Label "Installing VS Code Extensions"

Write-Host "[$script:CurrentStep/$script:TotalSteps] Installing VS Code Extensions..." -ForegroundColor Yellow
Write-Log "Installing VS Code Extensions..."

# Refresh PATH
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
            [System.Environment]::GetEnvironmentVariable("Path", "User")

if (Test-CommandExists 'code') {
    $extensions = @(
        "ms-vscode-remote.remote-containers",
        "github.copilot",
        "github.copilot-chat",
        "ms-toolsai.jupyter",
        "ms-toolsai.vscode-jupyter-cell-tags",
        "ms-toolsai.jupyter-keymap",
        "ms-toolsai.jupyter-renderers",
        "ms-toolsai.vscode-jupyter-slideshow",
        "shd101wyy.markdown-preview-enhanced",
        "ms-python.vscode-pylance",
        "ms-python.python",
        "ms-python.debugpy",
        "mechatroner.rainbow-csv",
        "qwtel.sqlite-viewer",
        "ms-vscode-remote.remote-wsl",
        "redhat.vscode-yaml",
        # OTLP lab additions
        "vscjava.vscode-java-pack",
        "vscjava.vscode-maven",
        "ms-azuretools.vscode-docker",
        "humao.rest-client"
    )

    foreach ($ext in $extensions) {
        Write-Host "  Installing $ext..." -ForegroundColor Gray
        code --install-extension $ext --force 2>&1 | Out-File -FilePath $LogFile -Append
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    [OK] $ext" -ForegroundColor Green
        } else {
            Write-Host "    [WARN] $ext (exit code: $LASTEXITCODE)" -ForegroundColor Yellow
        }
    }

    Write-Log "VS Code extensions installation completed" -Level Success
} else {
    Write-Log "VS Code CLI not available. Please restart and install extensions manually." -Level Warning
}

Write-Host ""

#region OTLP Lab Additions

# Step 17: Install Temurin JDK 21
Install-Software `
    -Name "Temurin JDK 21" `
    -PackageName "temurin21" `
    -CheckInstalled {
        (Test-CommandExists 'java') -and ((java -version 2>&1 | Out-String) -match 'version "21')
    } `
    -StepLabel "Installing Temurin JDK 21"

# Step 18: Install Maven
Install-Software `
    -Name "Maven" `
    -PackageName "maven" `
    -CheckInstalled {
        Test-CommandExists 'mvn'
    } `
    -StepLabel "Installing Maven"

# Step 19: Install jq
Install-Software `
    -Name "jq" `
    -PackageName "jq" `
    -CheckInstalled {
        Test-CommandExists 'jq'
    } `
    -StepLabel "Installing jq"

# Step 20: Install curl
Install-Software `
    -Name "curl" `
    -PackageName "curl" `
    -CheckInstalled {
        Test-CommandExists 'curl.exe'
    } `
    -StepLabel "Installing curl"

# Step 21: Install Grafana k6
Install-Software `
    -Name "Grafana k6" `
    -PackageName "k6" `
    -CheckInstalled {
        Test-CommandExists 'k6'
    } `
    -StepLabel "Installing Grafana k6"

# Step 22: Download OpenTelemetry Java agent
$script:CurrentStep++
Show-ProgressBar -Step $script:CurrentStep -Total $script:TotalSteps -Label "Downloading OpenTelemetry Java Agent"

Write-Host "[$script:CurrentStep/$script:TotalSteps] Checking OpenTelemetry Java agent $($OtlpConfig.JavaAgentVersion)..." -ForegroundColor Yellow
Write-Log "Checking OpenTelemetry Java agent..."

$javaAgentPath = Join-Path $OtlpConfig.ToolsDirectory "opentelemetry-javaagent.jar"
$javaAgentUrl = "https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/$($OtlpConfig.JavaAgentVersion)/opentelemetry-javaagent.jar"

if (-not $SkipChecks -and (Test-Path $javaAgentPath)) {
    Write-Log "OpenTelemetry Java agent already present. Skipping..." -Level Success
} else {
    try {
        New-Item -ItemType Directory -Path $OtlpConfig.ToolsDirectory -Force | Out-Null
        Write-Host "Downloading $javaAgentUrl..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $javaAgentUrl -OutFile $javaAgentPath -ErrorAction Stop
        Write-Log "OpenTelemetry Java agent downloaded to $javaAgentPath" -Level Success
    }
    catch {
        Write-Log "OpenTelemetry Java agent download error: $_" -Level Warning
    }
}

if (Test-Path $javaAgentPath) {
    [System.Environment]::SetEnvironmentVariable('OTEL_JAVAAGENT_PATH', $javaAgentPath, 'Machine')
    $env:OTEL_JAVAAGENT_PATH = $javaAgentPath
    Write-Log "OTEL_JAVAAGENT_PATH set to $javaAgentPath" -Level Success
}

Write-Host ""

# Step 23: Start Docker Engine
$dockerReady = Wait-DockerEngine

# Step 24: Pull observability Docker images
Install-ObservabilityImages -Images $OtlpConfig.Images -DockerReady $dockerReady

#endregion

#region Post-Installation Configuration

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "Post-Installation Configuration..." -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Configure Docker Desktop Kubernetes
Write-Host "Configuring Docker Desktop Kubernetes..." -ForegroundColor Yellow
$dockerSettings = Join-Path $env:APPDATA "Docker\settings.json"

if (Test-Path $dockerSettings) {
    try {
        $settings = Get-Content $dockerSettings -Raw | ConvertFrom-Json
        $settings | Add-Member -NotePropertyName 'kubernetesEnabled' -NotePropertyValue $true -Force
        $settings | ConvertTo-Json -Depth 32 | Set-Content $dockerSettings
        Write-Log "Docker Desktop Kubernetes enabled" -Level Success
        Write-Host "Kubernetes enabled in Docker Desktop settings." -ForegroundColor Green
    }
    catch {
        Write-Log "Docker Desktop Kubernetes auto-config failed: $_" -Level Warning
        Write-Host "Please enable Kubernetes manually in Docker Desktop." -ForegroundColor Yellow
    }
} else {
    Write-Host "Docker Desktop not configured yet. Configure after first launch." -ForegroundColor Yellow
}

Write-Host ""

# Configure Windows Terminal
Write-Host "Configuring Windows Terminal..." -ForegroundColor Yellow
$wtSettings = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

if (Test-Path $wtSettings) {
    try {
        $settings = Get-Content $wtSettings -Raw | ConvertFrom-Json

        if (-not $settings.profiles.defaults) {
            $settings.profiles | Add-Member -NotePropertyName 'defaults' -NotePropertyValue @{} -Force
        }

        $settings.profiles.defaults | Add-Member -NotePropertyName 'fontFace' -NotePropertyValue 'Fira Code' -Force
        $settings.profiles.defaults | Add-Member -NotePropertyName 'fontSize' -NotePropertyValue 12 -Force

        $cmdProfile = $settings.profiles.list | Where-Object {
            $_.name -eq 'Command Prompt' -or $_.commandline -like '*cmd.exe*'
        } | Select-Object -First 1

        if ($cmdProfile) {
            $settings | Add-Member -NotePropertyName 'defaultProfile' -NotePropertyValue $cmdProfile.guid -Force
        }

        $settings | ConvertTo-Json -Depth 32 | Set-Content $wtSettings
        Write-Log "Windows Terminal configured successfully" -Level Success
        Write-Host "Windows Terminal configured: Fira Code, size 12, default to CMD" -ForegroundColor Green
    }
    catch {
        Write-Log "Windows Terminal auto-config failed: $_" -Level Warning
        Write-Host "Please configure Windows Terminal manually." -ForegroundColor Yellow
    }
} else {
    Write-Host "Windows Terminal not configured yet. Launch it once, then re-run script." -ForegroundColor Yellow
}

#endregion

# Final summary
Write-Host ""
Show-ProgressBar -Step $script:TotalSteps -Total $script:TotalSteps -Label "Installation Complete!"
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "                  INSTALLATION COMPLETED" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "All software installations have been completed!" -ForegroundColor Green
Write-Host ""
Show-ImageSummary
Write-Host "OPENTELEMETRY JAVA AGENT:" -ForegroundColor Yellow
if (Test-Path $javaAgentPath) {
    Write-Host "  $javaAgentPath ($($OtlpConfig.JavaAgentVersion))" -ForegroundColor Green
    Write-Host "  Usage: java -javaagent:%OTEL_JAVAAGENT_PATH% -jar app.jar" -ForegroundColor Gray
} else {
    Write-Host "  Not downloaded - re-run this script or download manually:" -ForegroundColor Red
    Write-Host "  $javaAgentUrl" -ForegroundColor Gray
}
Write-Host ""
Write-Host "IMPORTANT NEXT STEPS:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. RESTART YOUR COMPUTER to ensure all PATH changes take effect" -ForegroundColor White
Write-Host ""
Write-Host "2. Launch Windows Terminal to verify configuration:" -ForegroundColor White
Write-Host "   - Default profile should be Command Prompt" -ForegroundColor Gray
Write-Host "   - Font should be Fira Code, size 12" -ForegroundColor Gray
Write-Host ""
Write-Host "3. After restart, configure Docker Desktop:" -ForegroundColor White
Write-Host "   - Launch Docker Desktop" -ForegroundColor Gray
Write-Host "   - Verify Kubernetes is enabled in Settings" -ForegroundColor Gray
Write-Host "   - If any image above is MISSING, run:" -ForegroundColor Gray
Write-Host "     pwsh -File install-lab-software-otlp.ps1 -ImagesOnly" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Complete WSL setup:" -ForegroundColor White
Write-Host "   - Run: wsl --install -d Ubuntu" -ForegroundColor Gray
Write-Host "   - Create Ubuntu user account when prompted" -ForegroundColor Gray
Write-Host ""
Write-Host "5. Verify UV and Java installation:" -ForegroundColor White
Write-Host "   - Run: uv --version" -ForegroundColor Gray
Write-Host "   - Run: java -version   (expect 21.x)" -ForegroundColor Gray
Write-Host ""
Write-Host "6. Run the installation-check.ps1 script to verify:" -ForegroundColor White
Write-Host "   - .\installation-check.ps1 -Otlp" -ForegroundColor Gray
Write-Host ""
Write-Host "Installation log saved to: $LogFile" -ForegroundColor Cyan
Write-Host ""
Write-Log "Installation completed successfully" -Level Success
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

#endregion
