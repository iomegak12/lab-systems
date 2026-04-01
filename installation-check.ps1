# Lab System Testing Script
# Tests all installed software components and reports status
# Run as Administrator for best results

param(
    [switch]$Detailed = $false,
    [switch]$QuickTest = $false
)

# Color coding for output
function Write-Status {
    param($Message, $Status, $Details = "")

    $timestamp = Get-Date -Format "HH:mm:ss"
    switch ($Status) {
        "PASS" {
            Write-Host "[$timestamp] " -NoNewline -ForegroundColor Gray
            Write-Host "✓ PASS" -NoNewline -ForegroundColor Green
            Write-Host " - $Message" -ForegroundColor White
        }
        "FAIL" {
            Write-Host "[$timestamp] " -NoNewline -ForegroundColor Gray
            Write-Host "✗ FAIL" -NoNewline -ForegroundColor Red
            Write-Host " - $Message" -ForegroundColor White
        }
        "WARN" {
            Write-Host "[$timestamp] " -NoNewline -ForegroundColor Gray
            Write-Host "⚠ WARN" -NoNewline -ForegroundColor Yellow
            Write-Host " - $Message" -ForegroundColor White
        }
        "INFO" {
            Write-Host "[$timestamp] " -NoNewline -ForegroundColor Gray
            Write-Host "ℹ INFO" -NoNewline -ForegroundColor Cyan
            Write-Host " - $Message" -ForegroundColor White
        }
    }

    if ($Detailed -and $Details) {
        Write-Host "    $Details" -ForegroundColor Gray
    }
}

function Write-Section {
    param([string]$Title)
    Write-Host "`n  ── $Title ──" -ForegroundColor DarkCyan
}

# Test results tracking
$TestResults = @{}

# Fixed Test-Command: null guard on timeout + no Invoke-Expression
function Test-Command {
    param($Command, $Name, $ExpectedPattern = "", $TimeoutSeconds = 30)

    try {
        $job = Start-Job -ScriptBlock {
            param($cmd)
            try {
                $output = & cmd /c $cmd 2>&1
                return @{Success = $true; Output = ($output | Out-String)}
            }
            catch {
                return @{Success = $false; Output = ""; Error = $_.Exception.Message}
            }
        } -ArgumentList $Command

        $completed = Wait-Job $job -Timeout $TimeoutSeconds
        if ($null -eq $completed) {
            Remove-Job $job -Force
            return @{Success = $false; Output = ""; Error = "Test timed out after ${TimeoutSeconds}s"}
        }

        $result = Receive-Job $job
        Remove-Job $job -Force

        if ($null -eq $result) {
            return @{Success = $false; Output = ""; Error = "No result returned from job"}
        }

        if ($result.Success) {
            $output = $result.Output
            if ($ExpectedPattern -and $output -notmatch $ExpectedPattern) {
                return @{Success = $false; Output = $output; Error = "Expected pattern '$ExpectedPattern' not found"}
            }
            return @{Success = $true; Output = $output}
        }
        else {
            return @{Success = $false; Output = ""; Error = $result.Error}
        }
    }
    catch {
        return @{Success = $false; Output = ""; Error = $_.Exception.Message}
    }
}

# Header
Clear-Host
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "                    LAB SYSTEM TESTING SCRIPT" -ForegroundColor Cyan
Write-Host "         AI Workshop for Database Teams — Environment Check" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

#region Core Development Tools

Write-Section "Core Development Tools"

# Test 1: Python 3.12
Write-Host "`nTesting Python 3.12..." -ForegroundColor Yellow
$pythonTest = Test-Command "python --version" "Python" "Python 3\.12"
if ($pythonTest.Success) {
    $parts = $pythonTest.Output.Trim() -split "\s+"
    $version = if ($parts.Count -ge 2) { $parts[1] } else { $pythonTest.Output.Trim() }
    Write-Status "Python $version" "PASS" $pythonTest.Output.Trim()
    $TestResults["Python"] = "PASS"

    # Test pip
    if (-not $QuickTest) {
        $pipTest = Test-Command "pip --version" "Pip"
        if ($pipTest.Success) {
            $pipVersion = ($pipTest.Output.Trim() -split "\s+")[1]
            Write-Status "pip $pipVersion" "PASS" $pipTest.Output.Trim()
        }
        else {
            Write-Status "pip not functional" "FAIL" $pipTest.Error
        }
    }
}
else {
    Write-Status "Python 3.12 not found or incorrect version" "FAIL" $pythonTest.Error
    $TestResults["Python"] = "FAIL"
}

# Test 2: Node.js
Write-Host "`nTesting Node.js..." -ForegroundColor Yellow
$nodeTest = Test-Command "node --version" "Node.js"
if ($nodeTest.Success) {
    $version = $nodeTest.Output.Trim()
    Write-Status "Node.js $version" "PASS" $version
    $TestResults["NodeJS"] = "PASS"

    # Test npm
    if (-not $QuickTest) {
        $npmTest = Test-Command "npm --version" "NPM"
        if ($npmTest.Success) {
            Write-Status "npm $($npmTest.Output.Trim())" "PASS" "npm version: $($npmTest.Output.Trim())"
        }
        else {
            Write-Status "npm not functional" "FAIL" $npmTest.Error
        }
    }
}
else {
    Write-Status "Node.js not found" "FAIL" $nodeTest.Error
    $TestResults["NodeJS"] = "FAIL"
}

# Test 3: Git
Write-Host "`nTesting Git..." -ForegroundColor Yellow
$gitTest = Test-Command "git --version" "Git"
if ($gitTest.Success) {
    $parts = $gitTest.Output.Trim() -split "\s+"
    $version = if ($parts.Count -ge 3) { $parts[2] } else { $gitTest.Output.Trim() }
    Write-Status "Git $version" "PASS" $gitTest.Output.Trim()
    $TestResults["Git"] = "PASS"
}
else {
    Write-Status "Git not found" "FAIL" $gitTest.Error
    $TestResults["Git"] = "FAIL"
}

# Test 4: GitHub CLI
Write-Host "`nTesting GitHub CLI..." -ForegroundColor Yellow
$ghTest = Test-Command "gh --version" "GitHub CLI"
if ($ghTest.Success) {
    $firstLine = ($ghTest.Output -split "`n")[0].Trim()
    Write-Status "GitHub CLI — $firstLine" "PASS" $firstLine
    $TestResults["GitHubCLI"] = "PASS"
}
else {
    Write-Status "GitHub CLI not found" "FAIL" $ghTest.Error
    $TestResults["GitHubCLI"] = "FAIL"
}

#endregion

#region Containers & Orchestration

Write-Section "Containers & Orchestration"

# Test 5: Docker Desktop
Write-Host "`nTesting Docker..." -ForegroundColor Yellow
$dockerTest = Test-Command "docker --version" "Docker"
if ($dockerTest.Success) {
    $version = $dockerTest.Output.Trim()
    Write-Status "Docker Engine — $version" "PASS" $version

    # Test Docker daemon
    $dockerInfoTest = Test-Command "docker info" "Docker Info" "" 10
    if ($dockerInfoTest.Success) {
        Write-Status "Docker daemon is running" "PASS"
        $TestResults["Docker"] = "PASS"

        # Test hello-world if not quick test
        if (-not $QuickTest) {
            Write-Status "Testing Docker functionality (pulling hello-world)..." "INFO"
            $dockerHelloTest = Test-Command "docker run --rm hello-world" "Docker Hello World" "" 60
            if ($dockerHelloTest.Success) {
                Write-Status "Docker container execution" "PASS" "hello-world container ran successfully"
            }
            else {
                Write-Status "Docker container execution" "WARN" "Could not run hello-world container"
            }
        }
    }
    else {
        Write-Status "Docker daemon not running" "FAIL" "Start Docker Desktop"
        $TestResults["Docker"] = "FAIL"
    }
}
else {
    Write-Status "Docker not found" "FAIL" $dockerTest.Error
    $TestResults["Docker"] = "FAIL"
}

# Test 6: Kubernetes (kubectl)
Write-Host "`nTesting Kubernetes..." -ForegroundColor Yellow
$kubectlTest = Test-Command "kubectl version --client" "Kubectl"
if ($kubectlTest.Success) {
    Write-Status "kubectl client installed" "PASS" "Kubernetes CLI available"

    # Test cluster connection
    $kubeClusterTest = Test-Command "kubectl cluster-info" "Kubernetes Cluster" "" 15
    if ($kubeClusterTest.Success) {
        Write-Status "Kubernetes cluster accessible" "PASS" "Cluster is reachable"
        $TestResults["Kubernetes"] = "PASS"
    }
    else {
        Write-Status "Kubernetes cluster not accessible" "WARN" "Enable Kubernetes in Docker Desktop Settings"
        $TestResults["Kubernetes"] = "WARN"
    }
}
else {
    Write-Status "kubectl not found" "FAIL" $kubectlTest.Error
    $TestResults["Kubernetes"] = "FAIL"
}

#endregion

#region IDEs & Editors

Write-Section "IDEs & Editors"

# Test 7: Visual Studio Code
Write-Host "`nTesting Visual Studio Code..." -ForegroundColor Yellow
$codeTest = Test-Command "code --version" "VS Code"
if ($codeTest.Success) {
    $version = ($codeTest.Output -split "`n")[0].Trim()
    Write-Status "Visual Studio Code $version" "PASS" $version
    $TestResults["VSCode"] = "PASS"
}
else {
    Write-Status "Visual Studio Code not found in PATH" "FAIL" $codeTest.Error
    $TestResults["VSCode"] = "FAIL"
}

#endregion

#region Browsers

Write-Section "Browsers"

# Test 8: Google Chrome
Write-Host "`nTesting Google Chrome..." -ForegroundColor Yellow
$chromePaths = @(
    "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
    "${env:LOCALAPPDATA}\Google\Chrome\Application\chrome.exe"
)

$chromeFound = $false
foreach ($path in $chromePaths) {
    if (Test-Path $path) {
        $chromeVersion = (Get-ItemProperty $path).VersionInfo.FileVersion
        Write-Status "Google Chrome $chromeVersion" "PASS" "Installed at: $path"
        $TestResults["Chrome"] = "PASS"
        $chromeFound = $true
        break
    }
}

if (-not $chromeFound) {
    Write-Status "Google Chrome not found" "FAIL" "Check installation"
    $TestResults["Chrome"] = "FAIL"
}

#endregion

#region Database Tools

Write-Section "Database Tools"

# Test 9 (was 12): SQL Server 2022
Write-Host "`nTesting SQL Server 2022..." -ForegroundColor Yellow

$sqlServerFound = $false
$sqlServerWarn = $false
$sqlInstanceName = ""
$sqlEdition = ""
$sqlServiceState = ""

try {
    # Check registry for SQL Server 2022 instances (version 16 = SQL Server 2022)
    $instanceNamesPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL"
    if (Test-Path $instanceNamesPath) {
        $instanceNames = Get-ItemProperty -Path $instanceNamesPath -ErrorAction SilentlyContinue

        foreach ($prop in $instanceNames.PSObject.Properties) {
            if ($prop.Name -like "PS*" -or $prop.Name -eq "PSChildName" -or
                $prop.Name -eq "PSParentPath" -or $prop.Name -eq "PSPath" -or
                $prop.Name -eq "PSProvider") { continue }

            $instanceKey = $prop.Value  # e.g. MSSQL16.SQLEXPRESS
            if ($instanceKey -like "MSSQL16.*") {
                # This is a SQL Server 2022 instance
                $sqlInstanceName = $prop.Name
                $setupPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceKey\Setup"

                if (Test-Path $setupPath) {
                    $setupInfo = Get-ItemProperty -Path $setupPath -ErrorAction SilentlyContinue
                    $sqlEdition = if ($setupInfo.Edition) { $setupInfo.Edition } else { "Unknown Edition" }
                }

                # Check the Windows service state
                $serviceName = "MSSQL`$$sqlInstanceName"
                if ($sqlInstanceName -eq "MSSQLSERVER") { $serviceName = "MSSQLSERVER" }

                $svc = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
                if ($null -eq $svc) {
                    # Try matching by display name pattern
                    $svc = Get-Service -ErrorAction SilentlyContinue |
                        Where-Object { $_.Name -like "MSSQL*" -and $_.DisplayName -like "*SQL Server*" } |
                        Select-Object -First 1
                }

                $sqlServiceState = if ($svc) { $svc.Status.ToString() } else { "Unknown" }

                $sqlServerFound = $true

                if ($svc -and $svc.Status -eq "Running") {
                    Write-Status "SQL Server 2022 [$sqlEdition] (Instance: $sqlInstanceName) — Service: Running" "PASS" `
                        "Registry key: $instanceKey | Service: $serviceName"
                    $TestResults["SQLServer2022"] = "PASS"
                }
                else {
                    Write-Status "SQL Server 2022 [$sqlEdition] (Instance: $sqlInstanceName) — Service: $sqlServiceState" "WARN" `
                        "SQL Server is installed but service is not running. Start via Services.msc or SQL Server Configuration Manager."
                    $TestResults["SQLServer2022"] = "WARN"
                    $sqlServerWarn = $true
                }
                break
            }
        }
    }

    if (-not $sqlServerFound) {
        # Fallback: check Windows services for any MSSQL service that looks like 2022
        $mssqlServices = Get-Service -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like "MSSQL*" -or $_.DisplayName -like "*SQL Server*" }

        if ($mssqlServices) {
            Write-Status "SQL Server service found but could not confirm 2022 version via registry" "WARN" `
                "Services detected: $($mssqlServices.Name -join ', ')"
            $TestResults["SQLServer2022"] = "WARN"
        }
        else {
            Write-Status "SQL Server 2022 not found" "FAIL" `
                "Install SQL Server 2022 Developer Edition from https://go.microsoft.com/fwlink/p/?linkid=2215158"
            $TestResults["SQLServer2022"] = "FAIL"
        }
    }
}
catch {
    Write-Status "SQL Server 2022 check encountered an error" "FAIL" $_.Exception.Message
    $TestResults["SQLServer2022"] = "FAIL"
}

# Test 10 (was 14): SQL Server Management Studio
Write-Host "`nTesting SQL Server Management Studio (SSMS)..." -ForegroundColor Yellow

$ssmsPaths = @(
    "${env:ProgramFiles(x86)}\Microsoft SQL Server Management Studio 20\Common7\IDE\Ssms.exe",
    "${env:ProgramFiles(x86)}\Microsoft SQL Server Management Studio 19\Common7\IDE\Ssms.exe",
    "${env:ProgramFiles}\Microsoft SQL Server Management Studio 20\Common7\IDE\Ssms.exe",
    "${env:ProgramFiles}\Microsoft SQL Server Management Studio 19\Common7\IDE\Ssms.exe"
)

$ssmsFound = $false

# First try registry
$ssmsRegPaths = @(
    "HKLM:\SOFTWARE\Microsoft\SQL Server Management Studio",
    "HKCU:\Software\Microsoft\SQL Server Management Studio"
)

foreach ($regPath in $ssmsRegPaths) {
    if (Test-Path $regPath) {
        try {
            $ssmsVersions = Get-ChildItem -Path $regPath -ErrorAction SilentlyContinue
            if ($ssmsVersions) {
                $latestVersion = ($ssmsVersions | Sort-Object Name -Descending | Select-Object -First 1).Name
                # Find the actual exe to get a precise file version
                foreach ($exePath in $ssmsPaths) {
                    if (Test-Path $exePath) {
                        $ssmsFileVersion = (Get-ItemProperty $exePath).VersionInfo.FileVersion
                        Write-Status "SSMS $ssmsFileVersion" "PASS" "Installed at: $exePath"
                        $TestResults["SSMS"] = "PASS"
                        $ssmsFound = $true
                        break
                    }
                }
                if (-not $ssmsFound) {
                    Write-Status "SSMS version $latestVersion (registry found, exe path unconfirmed)" "PASS" `
                        "Registry: $regPath\$latestVersion"
                    $TestResults["SSMS"] = "PASS"
                    $ssmsFound = $true
                }
                break
            }
        }
        catch { }
    }
}

# Fallback: path-based detection
if (-not $ssmsFound) {
    foreach ($path in $ssmsPaths) {
        if (Test-Path $path) {
            $ssmsVersion = (Get-ItemProperty $path).VersionInfo.FileVersion
            Write-Status "SSMS $ssmsVersion" "PASS" "Installed at: $path"
            $TestResults["SSMS"] = "PASS"
            $ssmsFound = $true
            break
        }
    }
}

if (-not $ssmsFound) {
    Write-Status "SQL Server Management Studio not found" "FAIL" `
        "Download from: https://aka.ms/ssmsfullsetup"
    $TestResults["SSMS"] = "FAIL"
}

#endregion

#region API Testing

Write-Section "API Testing"

# Test 11 (was 13): Postman
Write-Host "`nTesting Postman..." -ForegroundColor Yellow

$postmanPaths = @(
    "${env:LOCALAPPDATA}\Postman\Postman.exe",
    "${env:ProgramFiles}\Postman\Postman.exe",
    "${env:ProgramFiles(x86)}\Postman\Postman.exe"
)

$postmanFound = $false

# First try known paths
foreach ($path in $postmanPaths) {
    if (Test-Path $path) {
        $postmanVersion = (Get-ItemProperty $path).VersionInfo.FileVersion
        Write-Status "Postman $postmanVersion" "PASS" "Installed at: $path"
        $TestResults["Postman"] = "PASS"
        $postmanFound = $true
        break
    }
}

# Fallback: registry uninstall entries
if (-not $postmanFound) {
    $uninstallPaths = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall"
    )

    foreach ($regPath in $uninstallPaths) {
        if (Test-Path $regPath) {
            try {
                $postmanEntry = Get-ChildItem -Path $regPath -ErrorAction SilentlyContinue |
                    Get-ItemProperty -ErrorAction SilentlyContinue |
                    Where-Object { $_.DisplayName -like "*Postman*" } |
                    Select-Object -First 1

                if ($postmanEntry) {
                    $postmanVersion = if ($postmanEntry.DisplayVersion) { $postmanEntry.DisplayVersion } else { "unknown version" }
                    $postmanInstallLoc = if ($postmanEntry.InstallLocation) { $postmanEntry.InstallLocation } else { "unknown location" }
                    Write-Status "Postman $postmanVersion" "PASS" "Registry entry found at: $postmanInstallLoc"
                    $TestResults["Postman"] = "PASS"
                    $postmanFound = $true
                    break
                }
            }
            catch { }
        }
        if ($postmanFound) { break }
    }
}

if (-not $postmanFound) {
    Write-Status "Postman not found" "FAIL" "Download from: https://www.postman.com/downloads/"
    $TestResults["Postman"] = "FAIL"
}

#endregion

#region Python Tooling

Write-Section "Python Tooling"

# Test 12 (was 9): UV (Python package manager)
Write-Host "`nTesting UV..." -ForegroundColor Yellow
$uvTest = Test-Command "uv --version" "UV"
if ($uvTest.Success) {
    $version = $uvTest.Output.Trim()
    Write-Status "UV $version" "PASS" $version
    $TestResults["UV"] = "PASS"
}
else {
    Write-Status "UV not found" "FAIL" $uvTest.Error
    $TestResults["UV"] = "FAIL"
}

#endregion

#region System

Write-Section "System"

# Test 13 (was 10): WSL
Write-Host "`nTesting WSL..." -ForegroundColor Yellow
$wslTest = Test-Command "wsl --version" "WSL"
if ($wslTest.Success) {
    Write-Status "WSL installed" "PASS" "Windows Subsystem for Linux available"

    # Test WSL distributions
    $wslListTest = Test-Command "wsl --list --verbose" "WSL Distributions"
    if ($wslListTest.Success -and $wslListTest.Output -notmatch "No installed distributions") {
        Write-Status "WSL distributions available" "PASS" "Linux distributions installed"
        $TestResults["WSL"] = "PASS"
    }
    else {
        Write-Status "No WSL distributions installed" "WARN" "Install Ubuntu: wsl --install Ubuntu"
        $TestResults["WSL"] = "WARN"
    }
}
else {
    # Fallback: wsl --list works on older WSL that doesn't support --version
    $wslListFallback = Test-Command "wsl --list" "WSL"
    if ($wslListFallback.Success) {
        Write-Status "WSL installed (legacy)" "PASS" "WSL available"
        $TestResults["WSL"] = "PASS"
    }
    else {
        Write-Status "WSL not found" "FAIL" $wslTest.Error
        $TestResults["WSL"] = "FAIL"
    }
}

# Test 14 (was 11): PowerShell via Winget — CHECK ONLY, no upgrade
Write-Host "`nTesting PowerShell (via Winget)..." -ForegroundColor Yellow
$wingetTest = Test-Command "winget --version" "Winget"
if ($wingetTest.Success) {
    Write-Status "Winget $($wingetTest.Output.Trim()) available" "PASS" $wingetTest.Output.Trim()

    # List installed PowerShell — does NOT upgrade
    $psListTest = Test-Command "winget list --id Microsoft.PowerShell --accept-source-agreements" "PowerShell List" "" 30
    if ($psListTest.Success -and $psListTest.Output -match "Microsoft.PowerShell") {
        # Extract version from winget list output
        $psVersion = $PSVersionTable.PSVersion.ToString()
        Write-Status "PowerShell $psVersion (up to date check via winget)" "PASS" `
            "Use 'winget upgrade Microsoft.PowerShell' to update if needed"
        $TestResults["PowerShell"] = "PASS"
    }
    else {
        Write-Status "PowerShell not found via winget list" "WARN" `
            "Run: winget upgrade Microsoft.PowerShell to install latest version"
        $TestResults["PowerShell"] = "WARN"
    }
}
else {
    Write-Status "Winget not found" "FAIL" $wingetTest.Error
    $TestResults["PowerShell"] = "FAIL"
}

#endregion

# Summary Report
Write-Host "`n════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "                        TEST SUMMARY REPORT" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan

$passCount = ($TestResults.Values | Where-Object { $_ -eq "PASS" }).Count
$failCount = ($TestResults.Values | Where-Object { $_ -eq "FAIL" }).Count
$warnCount = ($TestResults.Values | Where-Object { $_ -eq "WARN" }).Count
$totalTests = $TestResults.Count

Write-Host "`nOverall Status:" -ForegroundColor White
Write-Host "  ✓ Passed:   $passCount/$totalTests" -ForegroundColor Green
Write-Host "  ✗ Failed:   $failCount/$totalTests" -ForegroundColor Red
Write-Host "  ⚠ Warnings: $warnCount/$totalTests" -ForegroundColor Yellow

Write-Host "`nDetailed Results:" -ForegroundColor White
foreach ($test in $TestResults.GetEnumerator() | Sort-Object Name) {
    switch ($test.Value) {
        "PASS" { Write-Host "  ✓ $($test.Key)" -ForegroundColor Green }
        "FAIL" { Write-Host "  ✗ $($test.Key)" -ForegroundColor Red }
        "WARN" { Write-Host "  ⚠ $($test.Key)" -ForegroundColor Yellow }
    }
}

# System Information
Write-Host "`n════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "                      SYSTEM INFORMATION" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan

$os = Get-CimInstance Win32_OperatingSystem
$computer = Get-CimInstance Win32_ComputerSystem
$memory = [math]::Round($computer.TotalPhysicalMemory / 1GB, 2)
$disk = Get-CimInstance Win32_LogicalDisk |
    Where-Object { $_.DriveType -eq 3 } |
    ForEach-Object { [math]::Round($_.FreeSpace / 1GB, 2) } |
    Measure-Object -Sum

Write-Host "Computer Name:      $($computer.Name)" -ForegroundColor Gray
Write-Host "OS Version:         $($os.Caption) $($os.Version)" -ForegroundColor Gray
Write-Host "Total RAM:          $memory GB" -ForegroundColor Gray
Write-Host "Free Disk Space:    $([math]::Round($disk.Sum, 2)) GB" -ForegroundColor Gray
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Gray
Write-Host "Execution Policy:   $(Get-ExecutionPolicy)" -ForegroundColor Gray

# Recommendations
Write-Host "`n════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "                        RECOMMENDATIONS" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan

if ($failCount -gt 0) {
    Write-Host "`nCritical Issues Found:" -ForegroundColor Red
    foreach ($test in $TestResults.GetEnumerator() | Where-Object { $_.Value -eq "FAIL" }) {
        switch ($test.Key) {
            "Docker"        { Write-Host "  • Start Docker Desktop and ensure it is running" -ForegroundColor White }
            "Python"        { Write-Host "  • Reinstall Python 3.12 or check PATH environment variable" -ForegroundColor White }
            "NodeJS"        { Write-Host "  • Reinstall Node.js or check PATH environment variable" -ForegroundColor White }
            "PowerShell"    { Write-Host "  • Install Winget or run: winget upgrade Microsoft.PowerShell" -ForegroundColor White }
            "SQLServer2022" { Write-Host "  • Install SQL Server 2022 Developer Edition from https://go.microsoft.com/fwlink/p/?linkid=2215158" -ForegroundColor White }
            "SSMS"          { Write-Host "  • Download SQL Server Management Studio from https://aka.ms/ssmsfullsetup" -ForegroundColor White }
            "Postman"       { Write-Host "  • Install Postman from https://www.postman.com/downloads/" -ForegroundColor White }
            default         { Write-Host "  • Check $($test.Key) installation and PATH configuration" -ForegroundColor White }
        }
    }
}

if ($warnCount -gt 0) {
    Write-Host "`nWarnings (Optional / Action Required):" -ForegroundColor Yellow
    foreach ($test in $TestResults.GetEnumerator() | Where-Object { $_.Value -eq "WARN" }) {
        switch ($test.Key) {
            "Kubernetes"    { Write-Host "  • Enable Kubernetes in Docker Desktop Settings → Kubernetes" -ForegroundColor White }
            "WSL"           { Write-Host "  • Install a Linux distribution: wsl --install Ubuntu" -ForegroundColor White }
            "PowerShell"    { Write-Host "  • Update PowerShell: winget upgrade Microsoft.PowerShell" -ForegroundColor White }
            "SQLServer2022" { Write-Host "  • Start SQL Server service: Open Services.msc or SQL Server Configuration Manager" -ForegroundColor White }
        }
    }
}

if ($failCount -eq 0 -and $warnCount -eq 0) {
    Write-Host "`n🎉 All systems operational! Lab environment is ready for training." -ForegroundColor Green
}
elseif ($failCount -eq 0) {
    Write-Host "`n✓ Core systems operational. Training can proceed with minor limitations." -ForegroundColor Yellow
}
else {
    Write-Host "`n⚠ Critical issues found. Please resolve failed tests before starting training." -ForegroundColor Red
}

Write-Host "`n════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Test completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan

# Export results to JSON if requested
if ($Detailed) {
    $reportPath = ".\LabTestReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    $report = @{
        TestDate   = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        SystemInfo = @{
            ComputerName      = $computer.Name
            OS                = "$($os.Caption) $($os.Version)"
            RAM_GB            = $memory
            FreeDisk_GB       = [math]::Round($disk.Sum, 2)
            PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        }
        TestResults = $TestResults
        Summary     = @{
            TotalTests = $totalTests
            Passed     = $passCount
            Failed     = $failCount
            Warnings   = $warnCount
        }
    }

    $report | ConvertTo-Json -Depth 3 | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Host "`nDetailed report saved to: $reportPath" -ForegroundColor Cyan
}
