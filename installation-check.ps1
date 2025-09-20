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

# Test results tracking
$TestResults = @{}

function Test-Command {
    param($Command, $Name, $ExpectedPattern = "", $TimeoutSeconds = 30)
    
    try {
        $job = Start-Job -ScriptBlock {
            param($cmd)
            try {
                $output = Invoke-Expression $cmd 2>&1
                return @{Success = $true; Output = $output}
            }
            catch {
                return @{Success = $false; Output = $_.Exception.Message}
            }
        } -ArgumentList $Command
        
        $result = Wait-Job $job -Timeout $TimeoutSeconds | Receive-Job
        Remove-Job $job -Force
        
        if ($result.Success) {
            $output = $result.Output | Out-String
            if ($ExpectedPattern -and $output -notmatch $ExpectedPattern) {
                return @{Success = $false; Output = $output; Error = "Expected pattern '$ExpectedPattern' not found"}
            }
            return @{Success = $true; Output = $output}
        } else {
            return @{Success = $false; Output = ""; Error = $result.Output}
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
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Test 1: Python 3.12
Write-Host "Testing Python 3.12..." -ForegroundColor Yellow
$pythonTest = Test-Command "python --version" "Python" "Python 3\.12"
if ($pythonTest.Success) {
    $version = ($pythonTest.Output -split " ")[1]
    Write-Status "Python $version" "PASS" $pythonTest.Output.Trim()
    $TestResults["Python"] = "PASS"
    
    # Test pip
    if (-not $QuickTest) {
        $pipTest = Test-Command "pip --version" "Pip"
        if ($pipTest.Success) {
            Write-Status "Python pip functionality" "PASS" $pipTest.Output.Trim()
        } else {
            Write-Status "Python pip functionality" "FAIL" $pipTest.Error
        }
    }
} else {
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
            Write-Status "NPM functionality" "PASS" "Version: $($npmTest.Output.Trim())"
        } else {
            Write-Status "NPM functionality" "FAIL" $npmTest.Error
        }
    }
} else {
    Write-Status "Node.js not found" "FAIL" $nodeTest.Error
    $TestResults["NodeJS"] = "FAIL"
}

# Test 3: Git
Write-Host "`nTesting Git..." -ForegroundColor Yellow
$gitTest = Test-Command "git --version" "Git"
if ($gitTest.Success) {
    $version = ($gitTest.Output -split " ")[2]
    Write-Status "Git $version" "PASS" $gitTest.Output.Trim()
    $TestResults["Git"] = "PASS"
} else {
    Write-Status "Git not found" "FAIL" $gitTest.Error
    $TestResults["Git"] = "FAIL"
}

# Test 4: GitHub CLI
Write-Host "`nTesting GitHub CLI..." -ForegroundColor Yellow
$ghTest = Test-Command "gh --version" "GitHub CLI"
if ($ghTest.Success) {
    $version = ($ghTest.Output -split "`n")[0]
    Write-Status "GitHub CLI" "PASS" $version.Trim()
    $TestResults["GitHubCLI"] = "PASS"
} else {
    Write-Status "GitHub CLI not found" "FAIL" $ghTest.Error
    $TestResults["GitHubCLI"] = "FAIL"
}

# Test 5: Docker Desktop
Write-Host "`nTesting Docker..." -ForegroundColor Yellow
$dockerTest = Test-Command "docker --version" "Docker"
if ($dockerTest.Success) {
    $version = $dockerTest.Output.Trim()
    Write-Status "Docker Engine" "PASS" $version
    
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
                Write-Status "Docker container execution" "PASS" "Hello-world container ran successfully"
            } else {
                Write-Status "Docker container execution" "WARN" "Could not run hello-world container"
            }
        }
    } else {
        Write-Status "Docker daemon not running" "FAIL" "Start Docker Desktop"
        $TestResults["Docker"] = "FAIL"
    }
} else {
    Write-Status "Docker not found" "FAIL" $dockerTest.Error
    $TestResults["Docker"] = "FAIL"
}

# Test 6: Kubernetes (kubectl)
Write-Host "`nTesting Kubernetes..." -ForegroundColor Yellow
$kubectlTest = Test-Command "kubectl version --client" "Kubectl"
if ($kubectlTest.Success) {
    Write-Status "kubectl client" "PASS" "Kubernetes CLI installed"
    
    # Test cluster connection
    $kubeClusterTest = Test-Command "kubectl cluster-info" "Kubernetes Cluster" "" 15
    if ($kubeClusterTest.Success) {
        Write-Status "Kubernetes cluster connectivity" "PASS" "Cluster is accessible"
        $TestResults["Kubernetes"] = "PASS"
    } else {
        Write-Status "Kubernetes cluster connectivity" "WARN" "Cluster not accessible - Enable Kubernetes in Docker Desktop"
        $TestResults["Kubernetes"] = "WARN"
    }
} else {
    Write-Status "kubectl not found" "FAIL" $kubectlTest.Error
    $TestResults["Kubernetes"] = "FAIL"
}

# Test 7: Visual Studio Code
Write-Host "`nTesting Visual Studio Code..." -ForegroundColor Yellow
$codeTest = Test-Command "code --version" "VS Code"
if ($codeTest.Success) {
    $version = ($codeTest.Output -split "`n")[0]
    Write-Status "Visual Studio Code $version" "PASS" $version
    $TestResults["VSCode"] = "PASS"
} else {
    Write-Status "Visual Studio Code not found in PATH" "FAIL" $codeTest.Error
    $TestResults["VSCode"] = "FAIL"
}

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

# Test 9: UV (Python package manager)
Write-Host "`nTesting UV..." -ForegroundColor Yellow
$uvTest = Test-Command "uv --version" "UV"
if ($uvTest.Success) {
    $version = $uvTest.Output.Trim()
    Write-Status "UV $version" "PASS" $version
    $TestResults["UV"] = "PASS"
} else {
    Write-Status "UV not found" "FAIL" $uvTest.Error
    $TestResults["UV"] = "FAIL"
}

# Test 10: WSL
Write-Host "`nTesting WSL..." -ForegroundColor Yellow
$wslTest = Test-Command "wsl --version" "WSL"
if ($wslTest.Success) {
    Write-Status "WSL is installed" "PASS" "Windows Subsystem for Linux available"
    
    # Test WSL distributions
    $wslListTest = Test-Command "wsl --list --verbose" "WSL Distributions"
    if ($wslListTest.Success -and $wslListTest.Output -notmatch "No installed distributions") {
        Write-Status "WSL distributions available" "PASS" "Linux distributions installed"
        $TestResults["WSL"] = "PASS"
    } else {
        Write-Status "No WSL distributions installed" "WARN" "Consider installing Ubuntu: wsl --install Ubuntu"
        $TestResults["WSL"] = "WARN"
    }
} else {
    Write-Status "WSL not found" "FAIL" $wslTest.Error
    $TestResults["WSL"] = "FAIL"
}

# Test 11: PowerShell Update via Winget
Write-Host "`nTesting PowerShell update via Winget..." -ForegroundColor Yellow
$wingetTest = Test-Command "winget --version" "Winget"
if ($wingetTest.Success) {
    Write-Status "Winget is available" "PASS" $wingetTest.Output.Trim()
    
    # Attempt to upgrade PowerShell
    $psUpgradeTest = Test-Command "winget upgrade --id Microsoft.PowerShell --accept-source-agreements --accept-package-agreements" "PowerShell Upgrade" "" 120
    if ($psUpgradeTest.Success -and $psUpgradeTest.Output -notmatch "No applicable upgrade found") {
        Write-Status "PowerShell updated successfully" "PASS" $psUpgradeTest.Output.Trim()
        $TestResults["PowerShellUpdate"] = "PASS"
    } elseif ($psUpgradeTest.Output -match "No applicable upgrade found") {
        Write-Status "PowerShell is already up to date" "PASS" "No upgrade needed"
        $TestResults["PowerShellUpdate"] = "PASS"
    } else {
        Write-Status "PowerShell update check failed" "WARN" $psUpgradeTest.Error
        $TestResults["PowerShellUpdate"] = "WARN"
    }
} else {
    Write-Status "Winget not found" "FAIL" $wingetTest.Error
    $TestResults["PowerShellUpdate"] = "FAIL"
}

# Summary Report
Write-Host "`n════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "                        TEST SUMMARY REPORT" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan

$passCount = ($TestResults.Values | Where-Object { $_ -eq "PASS" }).Count
$failCount = ($TestResults.Values | Where-Object { $_ -eq "FAIL" }).Count
$warnCount = ($TestResults.Values | Where-Object { $_ -eq "WARN" }).Count
$totalTests = $TestResults.Count

Write-Host "`nOverall Status:" -ForegroundColor White
Write-Host "  ✓ Passed: $passCount/$totalTests" -ForegroundColor Green
Write-Host "  ✗ Failed: $failCount/$totalTests" -ForegroundColor Red
Write-Host "  ⚠ Warnings: $warnCount/$totalTests" -ForegroundColor Yellow

Write-Host "`nDetailed Results:" -ForegroundColor White
foreach ($test in $TestResults.GetEnumerator() | Sort-Object Name) {
    $status = switch ($test.Value) {
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
$disk = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } | ForEach-Object {
    [math]::Round($_.FreeSpace / 1GB, 2)
} | Measure-Object -Sum

Write-Host "Computer Name: $($computer.Name)" -ForegroundColor Gray
Write-Host "OS Version: $($os.Caption) $($os.Version)" -ForegroundColor Gray
Write-Host "Total RAM: $memory GB" -ForegroundColor Gray
Write-Host "Free Disk Space: $([math]::Round($disk.Sum, 2)) GB" -ForegroundColor Gray
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Gray
Write-Host "Execution Policy: $(Get-ExecutionPolicy)" -ForegroundColor Gray

# Recommendations
Write-Host "`n════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "                        RECOMMENDATIONS" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan

if ($failCount -gt 0) {
    Write-Host "`nCritical Issues Found:" -ForegroundColor Red
    foreach ($test in $TestResults.GetEnumerator() | Where-Object { $_.Value -eq "FAIL" }) {
        switch ($test.Key) {
            "Docker" { Write-Host "  • Start Docker Desktop and ensure it's running" -ForegroundColor White }
            "Python" { Write-Host "  • Reinstall Python 3.12 or check PATH environment variable" -ForegroundColor White }
            "NodeJS" { Write-Host "  • Reinstall Node.js or check PATH environment variable" -ForegroundColor White }
            "PowerShellUpdate" { Write-Host "  • Install Winget (Windows Package Manager) to enable PowerShell updates" -ForegroundColor White }
            default { Write-Host "  • Check $($test.Key) installation and PATH configuration" -ForegroundColor White }
        }
    }
}

if ($warnCount -gt 0) {
    Write-Host "`nWarnings (Optional fixes):" -ForegroundColor Yellow
    foreach ($test in $TestResults.GetEnumerator() | Where-Object { $_.Value -eq "WARN" }) {
        switch ($test.Key) {
            "Kubernetes" { Write-Host "  • Enable Kubernetes in Docker Desktop settings" -ForegroundColor White }
            "WSL" { Write-Host "  • Install a Linux distribution: wsl --install Ubuntu" -ForegroundColor White }
            "PowerShellUpdate" { Write-Host "  • Manually update PowerShell using winget upgrade Microsoft.PowerShell" -ForegroundColor White }
        }
    }
}

if ($failCount -eq 0 -and $warnCount -eq 0) {
    Write-Host "`n🎉 All systems operational! Lab environment is ready for training." -ForegroundColor Green
} elseif ($failCount -eq 0) {
    Write-Host "`n✓ Core systems operational. Training can proceed with minor limitations." -ForegroundColor Yellow
} else {
    Write-Host "`n⚠ Critical issues found. Please resolve failed tests before starting training." -ForegroundColor Red
}

Write-Host "`n════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Test completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan

# Export results to JSON if requested
if ($Detailed) {
    $reportPath = ".\LabTestReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    $report = @{
        TestDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        SystemInfo = @{
            ComputerName = $computer.Name
            OS = "$($os.Caption) $($os.Version)"
            RAM_GB = $memory
            FreeDisk_GB = [math]::Round($disk.Sum, 2)
            PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        }
        TestResults = $TestResults
        Summary = @{
            TotalTests = $totalTests
            Passed = $passCount
            Failed = $failCount
            Warnings = $warnCount
        }
    }
    
    $report | ConvertTo-Json -Depth 3 | Out-File -FilePath $reportPath
    Write-Host "`nDetailed report saved to: $reportPath" -ForegroundColor Cyan
}