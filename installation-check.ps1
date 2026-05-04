#Requires -Version 5.1
<#
.SYNOPSIS
    Lab Environment Verification Suite — AI Workshop for Database Teams
.DESCRIPTION
    Verifies all required software is installed and operational.
    Standard mode (default) : 12 core component checks.
    Advanced mode (-Advanced): adds SQL Server 2022 + Postman (14 checks total).
.PARAMETER Advanced
    Run extended checks: SQL Server 2022 and Postman, in addition to all core checks.
.PARAMETER QuickTest
    Skip optional sub-tests (pip, npm, Docker hello-world) for a faster run.
.PARAMETER Detailed
    Export a full JSON report to the working directory after completion.
.EXAMPLE
    .\installation-check.ps1
    .\installation-check.ps1 -Advanced
    .\installation-check.ps1 -Advanced -Detailed
    .\installation-check.ps1 -QuickTest
#>
param(
    [switch]$Advanced  = $false,
    [switch]$Detailed  = $false,
    [switch]$QuickTest = $false
)

$ErrorActionPreference = "Continue"

# ══════════════════════════════════════════════════════════════════════════════
#  UI HELPERS
# ══════════════════════════════════════════════════════════════════════════════

function Write-Banner {
    $modeLabel   = if ($Advanced) { "Advanced  (SQL Server 2022 + Postman included)" } else { "Standard" }
    $totalChecks = if ($Advanced) { 14 } else { 12 }
    $startedAt   = Get-Date -Format "yyyy-MM-dd  HH:mm:ss"
    $w           = 66

    Write-Host ""
    Write-Host ("  ╔" + ("═" * $w) + "╗") -ForegroundColor Cyan
    Write-Host ("  ║" + (" " * $w) + "║") -ForegroundColor Cyan
    Write-Host ("  ║" + "  LAB ENVIRONMENT VERIFICATION SUITE".PadRight($w) + "║") -ForegroundColor White
    Write-Host ("  ║" + "  AI Workshop for Database Teams  ·  Windows Setup".PadRight($w) + "║") -ForegroundColor Cyan
    Write-Host ("  ║" + (" " * $w) + "║") -ForegroundColor Cyan
    Write-Host ("  ╠" + ("═" * $w) + "╣") -ForegroundColor DarkCyan
    Write-Host ("  ║" + ("  Mode     :  " + $modeLabel).PadRight($w) + "║") -ForegroundColor Yellow
    Write-Host ("  ║" + ("  Checks   :  $totalChecks components").PadRight($w) + "║") -ForegroundColor Gray
    Write-Host ("  ║" + ("  Started  :  $startedAt").PadRight($w) + "║") -ForegroundColor Gray
    Write-Host ("  ╚" + ("═" * $w) + "╝") -ForegroundColor Cyan
    Write-Host ""
}

function Write-SectionHeader {
    param([string]$Title)
    $pad  = [math]::Max(2, 52 - $Title.Length)
    $line = "─" * $pad
    Write-Host ""
    Write-Host "  ▶  " -NoNewline -ForegroundColor DarkYellow
    Write-Host $Title -NoNewline -ForegroundColor Magenta
    Write-Host "  $line" -ForegroundColor DarkGray
    Write-Host ""
}

function Write-Probing {
    param([string]$Name)
    Write-Host "      Checking $Name ..." -ForegroundColor DarkGray
}

function Write-Result {
    param(
        [string]$Label,
        [ValidateSet("PASS","FAIL","WARN","INFO","SKIP")]
        [string]$Status,
        [string]$Detail = ""
    )

    Write-Host "  " -NoNewline
    switch ($Status) {
        "PASS" {
            Write-Host " PASS " -BackgroundColor DarkGreen  -ForegroundColor White -NoNewline
            Write-Host "  $Label" -ForegroundColor White
        }
        "FAIL" {
            Write-Host " FAIL " -BackgroundColor DarkRed    -ForegroundColor White -NoNewline
            Write-Host "  $Label" -ForegroundColor White
        }
        "WARN" {
            Write-Host " WARN " -BackgroundColor DarkYellow -ForegroundColor Black -NoNewline
            Write-Host "  $Label" -ForegroundColor White
        }
        "INFO" {
            Write-Host " INFO " -BackgroundColor DarkCyan   -ForegroundColor Black -NoNewline
            Write-Host "  $Label" -ForegroundColor DarkGray
        }
        "SKIP" {
            Write-Host " SKIP " -BackgroundColor DarkGray   -ForegroundColor White -NoNewline
            Write-Host "  $Label" -ForegroundColor DarkGray
        }
    }

    if ($Detail) {
        Write-Host "          └─ $Detail" -ForegroundColor DarkGray
    }
}

function Write-SubResult {
    param(
        [string]$Label,
        [ValidateSet("PASS","FAIL","WARN","INFO")]
        [string]$Status,
        [string]$Detail = ""
    )

    Write-Host "  " -NoNewline
    switch ($Status) {
        "PASS" { Write-Host "    ✓  " -NoNewline -ForegroundColor Green  }
        "FAIL" { Write-Host "    ✗  " -NoNewline -ForegroundColor Red    }
        "WARN" { Write-Host "    ⚠  " -NoNewline -ForegroundColor Yellow }
        "INFO" { Write-Host "    ·  " -NoNewline -ForegroundColor Cyan   }
    }
    Write-Host $Label -ForegroundColor Gray
    if ($Detail) {
        Write-Host "             └─ $Detail" -ForegroundColor DarkGray
    }
}

function Write-Divider {
    Write-Host ("  " + ("─" * 66)) -ForegroundColor DarkGray
}

# ══════════════════════════════════════════════════════════════════════════════
#  CORE ENGINE
# ══════════════════════════════════════════════════════════════════════════════

$TestResults = [ordered]@{}

function Test-Command {
    param(
        [string]$Command,
        [string]$ExpectedPattern = "",
        [int]   $TimeoutSeconds  = 30
    )

    try {
        $job = Start-Job -ScriptBlock {
            param($cmd)
            try {
                $out = & cmd /c $cmd 2>&1
                $exitCode = $LASTEXITCODE
                return @{ Success = $true; Output = ($out | Out-String); ExitCode = $exitCode }
            }
            catch {
                return @{ Success = $false; Output = ""; Error = $_.Exception.Message; ExitCode = -1 }
            }
        } -ArgumentList $Command

        $completed = Wait-Job $job -Timeout $TimeoutSeconds
        if ($null -eq $completed) {
            Remove-Job $job -Force
            return @{ Success = $false; Output = ""; Error = "Timed out after ${TimeoutSeconds}s" }
        }

        $result = Receive-Job $job
        Remove-Job $job -Force

        if ($null -eq $result) {
            return @{ Success = $false; Output = ""; Error = "No result returned" }
        }

        if ($result.Success) {
            $out = $result.Output
            if ($null -ne $result.ExitCode -and $result.ExitCode -ne 0) {
                return @{ Success = $false; Output = $out; Error = "Process exited with code $($result.ExitCode)" }
            }
            if ($ExpectedPattern -and ($out -notmatch $ExpectedPattern)) {
                return @{ Success = $false; Output = $out; Error = "Pattern '$ExpectedPattern' not found" }
            }
            return @{ Success = $true; Output = $out }
        }

        return @{ Success = $false; Output = ""; Error = $result.Error }
    }
    catch {
        return @{ Success = $false; Output = ""; Error = $_.Exception.Message }
    }
}

# ══════════════════════════════════════════════════════════════════════════════
#  START
# ══════════════════════════════════════════════════════════════════════════════

Clear-Host
Write-Banner

# ──────────────────────────────────────────────────────────────────────────────
#  SECTION 1 — CORE DEVELOPMENT TOOLS
# ──────────────────────────────────────────────────────────────────────────────

Write-SectionHeader "Core Development Tools"

# ── Python ────────────────────────────────────────────────────────────────────
Write-Probing "Python 3.12"
$r = Test-Command "python --version" "Python 3\.12"
if ($r.Success) {
    $parts   = $r.Output.Trim() -split "\s+"
    $version = if ($parts.Count -ge 2) { $parts[1] } else { $r.Output.Trim() }
    Write-Result "Python $version" "PASS"
    $TestResults["Python"] = "PASS"

    if (-not $QuickTest) {
        $pip = Test-Command "pip --version"
        if ($pip.Success) {
            $pipVer = ($pip.Output.Trim() -split "\s+") | Select-Object -Index 1
            Write-SubResult "pip $pipVer" "PASS" $pip.Output.Trim()
        }
        else {
            Write-SubResult "pip — not functional" "FAIL" $pip.Error
        }
    }
}
else {
    Write-Result "Python 3.12 — not found or wrong version" "FAIL" $r.Error
    $TestResults["Python"] = "FAIL"
}

Write-Host ""

# ── Node.js ───────────────────────────────────────────────────────────────────
Write-Probing "Node.js"
$r = Test-Command "node --version"
if ($r.Success) {
    $version = $r.Output.Trim()
    Write-Result "Node.js $version" "PASS"
    $TestResults["NodeJS"] = "PASS"

    if (-not $QuickTest) {
        $npm = Test-Command "npm --version"
        if ($npm.Success) {
            Write-SubResult "npm $($npm.Output.Trim())" "PASS"
        }
        else {
            Write-SubResult "npm — not functional" "FAIL" $npm.Error
        }
    }
}
else {
    Write-Result "Node.js — not found" "FAIL" $r.Error
    $TestResults["NodeJS"] = "FAIL"
}

Write-Host ""

# ── Git ───────────────────────────────────────────────────────────────────────
Write-Probing "Git"
$r = Test-Command "git --version"
if ($r.Success) {
    $parts   = $r.Output.Trim() -split "\s+"
    $version = if ($parts.Count -ge 3) { $parts[2] } else { $r.Output.Trim() }
    Write-Result "Git $version" "PASS"
    $TestResults["Git"] = "PASS"
}
else {
    Write-Result "Git — not found" "FAIL" $r.Error
    $TestResults["Git"] = "FAIL"
}

Write-Host ""

# ── GitHub CLI ────────────────────────────────────────────────────────────────
Write-Probing "GitHub CLI"
$r = Test-Command "gh --version"
if ($r.Success) {
    $firstLine = ($r.Output -split "`n")[0].Trim()
    Write-Result "GitHub CLI  —  $firstLine" "PASS"
    $TestResults["GitHubCLI"] = "PASS"
}
else {
    Write-Result "GitHub CLI — not found" "FAIL" $r.Error
    $TestResults["GitHubCLI"] = "FAIL"
}

# ──────────────────────────────────────────────────────────────────────────────
#  SECTION 2 — CONTAINERS & ORCHESTRATION
# ──────────────────────────────────────────────────────────────────────────────

Write-SectionHeader "Containers & Orchestration"

# ── Docker ────────────────────────────────────────────────────────────────────
Write-Probing "Docker Desktop"
$r = Test-Command "docker --version"
if ($r.Success) {
    $version = $r.Output.Trim()
    Write-Result "Docker Engine  —  $version" "INFO"

    $daemon = Test-Command "docker info" "" 10
    if ($daemon.Success) {
        Write-SubResult "Docker daemon  —  running" "PASS"
        $TestResults["Docker"] = "PASS"

        if (-not $QuickTest) {
            Write-SubResult "Pulling hello-world container ..." "INFO"
            $hello = Test-Command "docker run --rm hello-world" "" 60
            if ($hello.Success) {
                Write-SubResult "Container execution  —  hello-world ran successfully" "PASS"
            }
            else {
                Write-SubResult "Container execution  —  could not run hello-world" "WARN"
            }
        }
    }
    else {
        Write-SubResult "Docker daemon  —  not running" "FAIL" "Launch Docker Desktop and wait for it to start"
        $TestResults["Docker"] = "FAIL"
    }
}
else {
    Write-Result "Docker Desktop — not found" "FAIL" $r.Error
    $TestResults["Docker"] = "FAIL"
}

Write-Host ""

# ── Kubernetes ────────────────────────────────────────────────────────────────
Write-Probing "Kubernetes (kubectl)"
$r = Test-Command "kubectl version --client"
if ($r.Success) {
    Write-Result "kubectl  —  client installed" "PASS"

    $cluster = Test-Command "kubectl cluster-info" "" 15
    if ($cluster.Success) {
        Write-SubResult "Cluster connectivity  —  accessible" "PASS"
        $TestResults["Kubernetes"] = "PASS"
    }
    else {
        Write-SubResult "Cluster connectivity  —  not reachable" "WARN" "Enable Kubernetes in Docker Desktop → Settings → Kubernetes"
        $TestResults["Kubernetes"] = "WARN"
    }
}
else {
    Write-Result "kubectl — not found" "FAIL" $r.Error
    $TestResults["Kubernetes"] = "FAIL"
}

# ──────────────────────────────────────────────────────────────────────────────
#  SECTION 3 — IDEs & EDITORS
# ──────────────────────────────────────────────────────────────────────────────

Write-SectionHeader "IDEs & Editors"

# ── VS Code ───────────────────────────────────────────────────────────────────
Write-Probing "Visual Studio Code"
$r = Test-Command "code --version"
if ($r.Success) {
    $version = ($r.Output -split "`n")[0].Trim()
    Write-Result "Visual Studio Code  $version" "PASS"
    $TestResults["VSCode"] = "PASS"
}
else {
    Write-Result "Visual Studio Code — not found in PATH" "FAIL" $r.Error
    $TestResults["VSCode"] = "FAIL"
}

# ──────────────────────────────────────────────────────────────────────────────
#  SECTION 4 — BROWSERS
# ──────────────────────────────────────────────────────────────────────────────

Write-SectionHeader "Browsers"

# ── Google Chrome ─────────────────────────────────────────────────────────────
Write-Probing "Google Chrome"
$chromePaths = @(
    "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
    "${env:LOCALAPPDATA}\Google\Chrome\Application\chrome.exe"
)

$chromeFound = $false
foreach ($path in $chromePaths) {
    if (Test-Path $path) {
        $ver = (Get-ItemProperty $path).VersionInfo.FileVersion
        Write-Result "Google Chrome  $ver" "PASS" $path
        $TestResults["Chrome"] = "PASS"
        $chromeFound = $true
        break
    }
}

if (-not $chromeFound) {
    Write-Result "Google Chrome — not found" "FAIL" "Check installation at ${env:ProgramFiles}\Google\Chrome"
    $TestResults["Chrome"] = "FAIL"
}

# ──────────────────────────────────────────────────────────────────────────────
#  SECTION 5 — DATABASE TOOLS
# ──────────────────────────────────────────────────────────────────────────────

Write-SectionHeader "Database Tools"

# ── SQL Server Management Studio (always) ─────────────────────────────────────
Write-Probing "SQL Server Management Studio (SSMS)"

$ssmsPaths = @(
    "${env:ProgramFiles(x86)}\Microsoft SQL Server Management Studio 20\Common7\IDE\Ssms.exe",
    "${env:ProgramFiles(x86)}\Microsoft SQL Server Management Studio 19\Common7\IDE\Ssms.exe",
    "${env:ProgramFiles}\Microsoft SQL Server Management Studio 20\Common7\IDE\Ssms.exe",
    "${env:ProgramFiles}\Microsoft SQL Server Management Studio 19\Common7\IDE\Ssms.exe"
)
$ssmsRegPaths = @(
    "HKLM:\SOFTWARE\Microsoft\SQL Server Management Studio",
    "HKCU:\Software\Microsoft\SQL Server Management Studio"
)

$ssmsFound = $false

foreach ($regPath in $ssmsRegPaths) {
    if (Test-Path $regPath) {
        try {
            $ssmsVersions = Get-ChildItem -Path $regPath -ErrorAction SilentlyContinue
            if ($ssmsVersions) {
                foreach ($exePath in $ssmsPaths) {
                    if (Test-Path $exePath) {
                        $ver = (Get-ItemProperty $exePath).VersionInfo.FileVersion
                        Write-Result "SSMS  $ver" "PASS" $exePath
                        $TestResults["SSMS"] = "PASS"
                        $ssmsFound = $true
                        break
                    }
                }

            }
        }
        catch { }
    }
    if ($ssmsFound) { break }
}

if (-not $ssmsFound) {
    foreach ($exePath in $ssmsPaths) {
        if (Test-Path $exePath) {
            $ver = (Get-ItemProperty $exePath).VersionInfo.FileVersion
            Write-Result "SSMS  $ver" "PASS" $exePath
            $TestResults["SSMS"] = "PASS"
            $ssmsFound = $true
            break
        }
    }
}

if (-not $ssmsFound) {
    Write-Result "SQL Server Management Studio — not found" "FAIL" "Download: https://aka.ms/ssmsfullsetup"
    $TestResults["SSMS"] = "FAIL"
}

Write-Host ""

# ── SQL Server 2022 (Advanced only) ───────────────────────────────────────────
if ($Advanced) {
    Write-Probing "SQL Server 2022"

    $sqlFound       = $false
    $sqlInstanceName = ""
    $sqlEdition      = ""

    try {
        $regInstancePath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL"
        if (Test-Path $regInstancePath) {
            $instanceProps = Get-ItemProperty -Path $regInstancePath -ErrorAction SilentlyContinue

            foreach ($prop in $instanceProps.PSObject.Properties) {
                if ($prop.Name -like "PS*") { continue }
                $instanceKey = $prop.Value   # e.g. MSSQL16.SQLEXPRESS

                if ($instanceKey -like "MSSQL16.*") {
                    $sqlInstanceName = $prop.Name
                    $setupPath       = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceKey\Setup"

                    if (Test-Path $setupPath) {
                        $setup      = Get-ItemProperty -Path $setupPath -ErrorAction SilentlyContinue
                        $sqlEdition = if ($setup.Edition) { $setup.Edition } else { "Unknown Edition" }
                    }

                    $serviceName = if ($sqlInstanceName -eq "MSSQLSERVER") {
                        "MSSQLSERVER"
                    }
                    else {
                        "MSSQL`$$sqlInstanceName"
                    }

                    $svc = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
                    if ($null -eq $svc) {
                        $svc = Get-Service -ErrorAction SilentlyContinue |
                            Where-Object { $_.Name -like "MSSQL*" -and $_.DisplayName -like "*SQL Server*" } |
                            Select-Object -First 1
                    }

                    $sqlFound = $true

                    if ($svc -and $svc.Status -eq "Running") {
                        Write-Result "SQL Server 2022  [$sqlEdition]  Instance: $sqlInstanceName" "PASS" `
                            "Service: $serviceName — Running"
                        $TestResults["SQLServer2022"] = "PASS"
                    }
                    else {
                        $state = if ($svc) { $svc.Status.ToString() } else { "Unknown" }
                        Write-Result "SQL Server 2022  [$sqlEdition]  Instance: $sqlInstanceName" "WARN" `
                            "Service state: $state — Start via Services.msc or SQL Server Configuration Manager"
                        $TestResults["SQLServer2022"] = "WARN"
                    }
                    break
                }
            }
        }

        if (-not $sqlFound) {
            $fallbackSvcs = Get-Service -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -like "MSSQL*" -or $_.DisplayName -like "*SQL Server*" }

            if ($fallbackSvcs) {
                Write-Result "SQL Server — service detected (version unconfirmed via registry)" "WARN" `
                    "Services: $($fallbackSvcs.Name -join ', ')"
                $TestResults["SQLServer2022"] = "WARN"
            }
            else {
                Write-Result "SQL Server 2022 — not found" "FAIL" `
                    "Install Developer Edition: https://go.microsoft.com/fwlink/p/?linkid=2215158"
                $TestResults["SQLServer2022"] = "FAIL"
            }
        }
    }
    catch {
        Write-Result "SQL Server 2022 — check error" "FAIL" $_.Exception.Message
        $TestResults["SQLServer2022"] = "FAIL"
    }
}

# ──────────────────────────────────────────────────────────────────────────────
#  SECTION 6 — API TESTING  (Advanced only)
# ──────────────────────────────────────────────────────────────────────────────

if ($Advanced) {
    Write-SectionHeader "API Testing"

    # ── Postman ───────────────────────────────────────────────────────────────
    Write-Probing "Postman"

    $postmanPaths = @(
        "${env:LOCALAPPDATA}\Postman\Postman.exe",
        "${env:ProgramFiles}\Postman\Postman.exe",
        "${env:ProgramFiles(x86)}\Postman\Postman.exe"
    )
    $uninstallRoots = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall"
    )

    $postmanFound = $false

    foreach ($path in $postmanPaths) {
        if (Test-Path $path) {
            $ver = (Get-ItemProperty $path).VersionInfo.FileVersion
            Write-Result "Postman  $ver" "PASS" $path
            $TestResults["Postman"] = "PASS"
            $postmanFound = $true
            break
        }
    }

    if (-not $postmanFound) {
        foreach ($root in $uninstallRoots) {
            if (-not (Test-Path $root)) { continue }
            try {
                $entry = Get-ChildItem -Path $root -ErrorAction SilentlyContinue |
                    Get-ItemProperty -ErrorAction SilentlyContinue |
                    Where-Object { $_.DisplayName -like "*Postman*" } |
                    Select-Object -First 1

                if ($entry) {
                    $ver = if ($entry.DisplayVersion) { $entry.DisplayVersion } else { "unknown version" }
                    $loc = if ($entry.InstallLocation) { $entry.InstallLocation } else { "unknown location" }
                    Write-Result "Postman  $ver" "PASS" $loc
                    $TestResults["Postman"] = "PASS"
                    $postmanFound = $true
                    break
                }
            }
            catch { }
        }
    }

    if (-not $postmanFound) {
        Write-Result "Postman — not found" "FAIL" "Download: https://www.postman.com/downloads/"
        $TestResults["Postman"] = "FAIL"
    }
}

# ──────────────────────────────────────────────────────────────────────────────
#  SECTION 7 — PYTHON TOOLING
# ──────────────────────────────────────────────────────────────────────────────

Write-SectionHeader "Python Tooling"

# ── UV ────────────────────────────────────────────────────────────────────────
Write-Probing "UV (Python package manager)"
$r = Test-Command "uv --version"
if ($r.Success) {
    $version = $r.Output.Trim()
    Write-Result "UV  $version" "PASS"
    $TestResults["UV"] = "PASS"
}
else {
    Write-Result "UV — not found" "FAIL" "Install: pip install uv"
    $TestResults["UV"] = "FAIL"
}

# ──────────────────────────────────────────────────────────────────────────────
#  SECTION 8 — SYSTEM
# ──────────────────────────────────────────────────────────────────────────────

Write-SectionHeader "System"

# ── WSL ───────────────────────────────────────────────────────────────────────
Write-Probing "Windows Subsystem for Linux (WSL)"
$r = Test-Command "wsl --version"
if ($r.Success) {
    Write-Result "WSL  —  installed" "PASS"

    $distros = Test-Command "wsl --list --verbose"
    if ($distros.Success -and $distros.Output -notmatch "No installed distributions") {
        Write-SubResult "Linux distributions  —  available" "PASS"
        $TestResults["WSL"] = "PASS"
    }
    else {
        Write-SubResult "Linux distributions  —  none installed" "WARN" "Run: wsl --install Ubuntu"
        $TestResults["WSL"] = "WARN"
    }
}
else {
    $fallback = Test-Command "wsl --list"
    if ($fallback.Success) {
        Write-Result "WSL  —  installed (legacy build)" "PASS"
        $TestResults["WSL"] = "PASS"
    }
    else {
        Write-Result "WSL — not found" "FAIL" "Enable via: wsl --install"
        $TestResults["WSL"] = "FAIL"
    }
}

Write-Host ""

# ── PowerShell via Winget (check only — no upgrade triggered) ─────────────────
Write-Probing "PowerShell  (via Winget)"
$r = Test-Command "winget --version"
if ($r.Success) {
    Write-Result "Winget  $($r.Output.Trim())  —  available" "PASS"

    $psList = Test-Command "winget list --id Microsoft.PowerShell --accept-source-agreements" "" 30
    if ($psList.Success -and $psList.Output -match "Microsoft.PowerShell") {
        $psVer = $PSVersionTable.PSVersion.ToString()
        Write-SubResult "PowerShell  $psVer  —  current" "PASS" "To update: winget upgrade Microsoft.PowerShell"
        $TestResults["PowerShell"] = "PASS"
    }
    else {
        Write-SubResult "PowerShell  —  not found via winget list" "WARN" "Run: winget upgrade Microsoft.PowerShell"
        $TestResults["PowerShell"] = "WARN"
    }
}
else {
    Write-Result "Winget — not found" "FAIL" "Install Windows Package Manager from the Microsoft Store"
    $TestResults["PowerShell"] = "FAIL"
}

# ══════════════════════════════════════════════════════════════════════════════
#  SUMMARY
# ══════════════════════════════════════════════════════════════════════════════

$passCount  = ($TestResults.Values | Where-Object { $_ -eq "PASS" }).Count
$failCount  = ($TestResults.Values | Where-Object { $_ -eq "FAIL" }).Count
$warnCount  = ($TestResults.Values | Where-Object { $_ -eq "WARN" }).Count
$totalTests = $TestResults.Count

$w = 66
Write-Host ""
Write-Host ("  ╔" + ("═" * $w) + "╗") -ForegroundColor Cyan
Write-Host ("  ║" + "  VERIFICATION RESULTS SUMMARY".PadRight($w) + "║") -ForegroundColor White
Write-Host ("  ╠" + ("═" * $w) + "╣") -ForegroundColor DarkCyan

# Counts row
$countsLine = ("  ✓ Passed: $passCount   ✗ Failed: $failCount   ⚠ Warned: $warnCount   · Total: $totalTests").PadRight($w)
Write-Host "  ║" -NoNewline -ForegroundColor Cyan
Write-Host ("  ✓ Passed: ") -NoNewline -ForegroundColor DarkGray
Write-Host ("$passCount") -NoNewline -ForegroundColor Green
Write-Host ("   ✗ Failed: ") -NoNewline -ForegroundColor DarkGray
Write-Host ("$failCount") -NoNewline -ForegroundColor Red
Write-Host ("   ⚠ Warned: ") -NoNewline -ForegroundColor DarkGray
Write-Host ("$warnCount") -NoNewline -ForegroundColor Yellow
Write-Host ("   · Total: $totalTests".PadRight($w - 38) + "║") -ForegroundColor DarkGray

Write-Host ("  ╠" + ("═" * $w) + "╣") -ForegroundColor DarkCyan

# Per-test rows
foreach ($test in $TestResults.GetEnumerator()) {
    $key    = $test.Key.PadRight(22)
    $status = $test.Value

    Write-Host "  ║  " -NoNewline -ForegroundColor Cyan
    Write-Host $key -NoNewline -ForegroundColor Gray

    switch ($status) {
        "PASS" {
            Write-Host " PASS " -BackgroundColor DarkGreen  -ForegroundColor White -NoNewline
            Write-Host (" " * ($w - 30)) -NoNewline
        }
        "FAIL" {
            Write-Host " FAIL " -BackgroundColor DarkRed    -ForegroundColor White -NoNewline
            Write-Host (" " * ($w - 30)) -NoNewline
        }
        "WARN" {
            Write-Host " WARN " -BackgroundColor DarkYellow -ForegroundColor Black -NoNewline
            Write-Host (" " * ($w - 30)) -NoNewline
        }
    }
    Write-Host "  ║" -ForegroundColor Cyan
}

Write-Host ("  ╚" + ("═" * $w) + "╝") -ForegroundColor Cyan

# ══════════════════════════════════════════════════════════════════════════════
#  SYSTEM INFORMATION
# ══════════════════════════════════════════════════════════════════════════════

Write-Host ""
Write-Host ("  ╔" + ("═" * $w) + "╗") -ForegroundColor DarkCyan
Write-Host ("  ║" + "  SYSTEM INFORMATION".PadRight($w) + "║") -ForegroundColor White
Write-Host ("  ╠" + ("═" * $w) + "╣") -ForegroundColor DarkCyan

$os       = Get-CimInstance Win32_OperatingSystem
$computer = Get-CimInstance Win32_ComputerSystem
$memory   = [math]::Round($computer.TotalPhysicalMemory / 1GB, 2)
$disk     = (Get-CimInstance Win32_LogicalDisk |
    Where-Object { $_.DriveType -eq 3 } |
    ForEach-Object { [math]::Round($_.FreeSpace / 1GB, 2) } |
    Measure-Object -Sum).Sum

function Write-InfoRow {
    param([string]$Key, [string]$Value)
    $row = ("  " + $Key.PadRight(20) + $Value).PadRight($w)
    Write-Host "  ║" -NoNewline -ForegroundColor DarkCyan
    Write-Host ("  " + $Key.PadRight(20)) -NoNewline -ForegroundColor DarkGray
    Write-Host $Value.PadRight($w - 22) -NoNewline -ForegroundColor Gray
    Write-Host "║" -ForegroundColor DarkCyan
}

Write-InfoRow "Computer"       $computer.Name
Write-InfoRow "OS"             "$($os.Caption) $($os.Version)"
Write-InfoRow "Total RAM"      "$memory GB"
Write-InfoRow "Free Disk"      "$([math]::Round($disk, 2)) GB"
Write-InfoRow "PowerShell"     $PSVersionTable.PSVersion.ToString()
Write-InfoRow "Exec Policy"    (Get-ExecutionPolicy)
Write-InfoRow "Check Mode"     $(if ($Advanced) { "Advanced" } else { "Standard" })

Write-Host ("  ╚" + ("═" * $w) + "╝") -ForegroundColor DarkCyan

# ══════════════════════════════════════════════════════════════════════════════
#  RECOMMENDATIONS
# ══════════════════════════════════════════════════════════════════════════════

if ($failCount -gt 0 -or $warnCount -gt 0) {
    Write-Host ""
    Write-Host ("  ╔" + ("═" * $w) + "╗") -ForegroundColor DarkYellow
    Write-Host ("  ║" + "  RECOMMENDATIONS".PadRight($w) + "║") -ForegroundColor White
    Write-Host ("  ╠" + ("═" * $w) + "╣") -ForegroundColor DarkYellow

    if ($failCount -gt 0) {
        Write-Host ("  ║" + "  Critical — resolve before starting the workshop:".PadRight($w) + "║") -ForegroundColor Red
        foreach ($test in $TestResults.GetEnumerator() | Where-Object { $_.Value -eq "FAIL" }) {
            $msg = switch ($test.Key) {
                "Python"        { "Reinstall Python 3.12 and ensure it is added to PATH" }
                "NodeJS"        { "Reinstall Node.js LTS and ensure it is added to PATH" }
                "Docker"        { "Launch Docker Desktop and wait for it to fully start" }
                "VSCode"        { "Reinstall VS Code and choose 'Add to PATH' during setup" }
                "Chrome"        { "Install Google Chrome from https://www.google.com/chrome" }
                "SSMS"          { "Download SSMS from https://aka.ms/ssmsfullsetup" }
                "SQLServer2022" { "Install SQL Server 2022 Dev Ed: https://go.microsoft.com/fwlink/p/?linkid=2215158" }
                "Postman"       { "Install Postman from https://www.postman.com/downloads/" }
                "UV"            { "Install UV: pip install uv" }
                "PowerShell"    { "Install Winget or run: winget upgrade Microsoft.PowerShell" }
                default         { "Check $($test.Key) installation and PATH configuration" }
            }
            Write-Host ("  ║" + "    •  $msg".PadRight($w) + "║") -ForegroundColor White
        }
    }

    if ($failCount -gt 0 -and $warnCount -gt 0) {
        Write-Host ("  ║" + (" " * $w) + "║") -ForegroundColor DarkYellow
    }

    if ($warnCount -gt 0) {
        Write-Host ("  ║" + "  Advisory — optional or can be resolved after install:".PadRight($w) + "║") -ForegroundColor Yellow
        foreach ($test in $TestResults.GetEnumerator() | Where-Object { $_.Value -eq "WARN" }) {
            $msg = switch ($test.Key) {
                "Kubernetes"    { "Enable Kubernetes in Docker Desktop → Settings → Kubernetes" }
                "WSL"           { "Install Ubuntu: wsl --install Ubuntu" }
                "PowerShell"    { "Update PowerShell: winget upgrade Microsoft.PowerShell" }
                "SQLServer2022" { "Start the SQL Server service via Services.msc or SQL Server Configuration Manager" }
                default         { "Review $($test.Key) configuration" }
            }
            Write-Host ("  ║" + "    ⚠  $msg".PadRight($w) + "║") -ForegroundColor White
        }
    }

    Write-Host ("  ╚" + ("═" * $w) + "╝") -ForegroundColor DarkYellow
}

# ══════════════════════════════════════════════════════════════════════════════
#  VERDICT
# ══════════════════════════════════════════════════════════════════════════════

Write-Host ""
if ($failCount -eq 0 -and $warnCount -eq 0) {
    Write-Host "  ✦  " -NoNewline -ForegroundColor Green
    Write-Host "All systems operational. " -NoNewline -ForegroundColor Green
    Write-Host "Lab environment is fully ready for training." -ForegroundColor White
}
elseif ($failCount -eq 0) {
    Write-Host "  ●  " -NoNewline -ForegroundColor Yellow
    Write-Host "Core systems operational. " -NoNewline -ForegroundColor Yellow
    Write-Host "Training can proceed — review warnings above." -ForegroundColor White
}
else {
    Write-Host "  ✖  " -NoNewline -ForegroundColor Red
    Write-Host "Critical issues detected. " -NoNewline -ForegroundColor Red
    Write-Host "Resolve failed checks before starting training." -ForegroundColor White
}

Write-Host ""
Write-Host ("  " + ("─" * $w)) -ForegroundColor DarkGray
Write-Host "  Completed at  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor DarkGray
if (-not $Advanced) {
    Write-Host "  Tip: run with -Advanced to also check SQL Server 2022 and Postman." -ForegroundColor DarkGray
}
Write-Host ("  " + ("─" * $w)) -ForegroundColor DarkGray
Write-Host ""

# ══════════════════════════════════════════════════════════════════════════════
#  JSON EXPORT  (-Detailed)
# ══════════════════════════════════════════════════════════════════════════════

if ($Detailed) {
    $reportPath = ".\LabTestReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    @{
        TestDate   = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Mode       = if ($Advanced) { "Advanced" } else { "Standard" }
        SystemInfo = @{
            ComputerName      = $computer.Name
            OS                = "$($os.Caption) $($os.Version)"
            RAM_GB            = $memory
            FreeDisk_GB       = [math]::Round($disk, 2)
            PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        }
        TestResults = $TestResults
        Summary     = @{
            TotalTests = $totalTests
            Passed     = $passCount
            Failed     = $failCount
            Warnings   = $warnCount
        }
    } | ConvertTo-Json -Depth 3 | Out-File -FilePath $reportPath -Encoding UTF8

    Write-Host "  Report saved  →  $reportPath" -ForegroundColor Cyan
    Write-Host ""
}
