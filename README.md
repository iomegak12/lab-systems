# Lab Systems Environment Setup

Automated installation and verification scripts for setting up a complete development and training lab environment on Windows.

## Overview

This repository contains scripts to automate the installation and verification of essential development tools and software required for lab training environments.

## Features

- **Automated Installation** - Fully automated software installation via Windows Package Manager (winget)
- **Administrator Validation** - Ensures proper privileges before installation
- **Comprehensive Testing** - Validates all installed components with detailed reporting
- **Logging** - Generates timestamped installation and test logs
- **VS Code Extensions** - Auto-installs essential VS Code extensions for development

## Software Components

The scripts install and verify the following software:

### Core Development Tools
- **Python 3.12** - Programming language with pip package manager
- **Node.js** - JavaScript runtime with npm
- **Git** - Version control system
- **GitHub CLI** - GitHub command-line interface
- **Visual Studio Code** - Code editor with extensions

### Container & Orchestration
- **Docker Desktop** - Container platform with Kubernetes support
- **kubectl** - Kubernetes command-line tool
- **Multipass** - Ubuntu VM manager

### System Tools
- **WSL (Windows Subsystem for Linux)** - Linux environment on Windows
- **Ubuntu** - Default WSL distribution
- **Google Chrome** - Web browser
- **UV** - Fast Python package manager
- **Winget** - Windows Package Manager

### VS Code Extensions
- Remote - Containers
- GitHub Copilot & Copilot Chat
- Jupyter (with Cell Tags, Keymap, Renderers, Slideshow)
- Markdown Preview Enhanced
- Python (Pylance, Python, Debugger)
- Rainbow CSV
- SQLite Viewer
- WSL
- YAML

## Scripts

### `install-lab-software.cmd`

Automated installation script that installs all required software components.

**Requirements:**
- Windows 10/11
- Administrator privileges
- Internet connection

**Usage:**
```cmd
# Right-click and select "Run as administrator"
install-lab-software.cmd
```

**Features:**
- Checks for administrator privileges
- Auto-installs winget on Windows 10 if missing
- Silent installations with minimal user interaction
- Refreshes PATH environment variables
- Enables Kubernetes in Docker Desktop
- Installs all VS Code extensions
- Generates detailed installation log

### `installation-check.ps1`

PowerShell script that tests all installed software and generates a comprehensive report.

**Requirements:**
- PowerShell 5.1 or later
- Installed software components (run install script first)

**Usage:**
```powershell
# Standard test
.\installation-check.ps1

# Quick test (skips extended checks)
.\installation-check.ps1 -QuickTest

# Detailed test with JSON report
.\installation-check.ps1 -Detailed
```

**Features:**
- Tests all software installations
- Validates Docker daemon status
- Checks Kubernetes cluster connectivity
- Tests WSL distributions
- Updates PowerShell via winget
- Color-coded pass/fail/warning output
- System information reporting
- Actionable recommendations
- JSON export for detailed analysis

## Installation Process

### Step 1: Run Installation Script

```cmd
# Run as Administrator
install-lab-software.cmd
```

This will:
1. Verify administrator privileges
2. Install/verify winget
3. Install all software components
4. Configure Docker Desktop for Kubernetes
5. Install WSL and Ubuntu
6. Install UV via pip
7. Install VS Code extensions
8. Generate installation log

### Step 2: Restart Your Computer

After installation completes, **restart your computer** to ensure all PATH changes take effect.

### Step 3: Complete WSL Setup (First Time Only)

```cmd
# Launch WSL and create user account
wsl
```

Follow prompts to create Ubuntu username and password.

### Step 4: Start Docker Desktop

1. Launch Docker Desktop
2. Verify Kubernetes is enabled (Settings > Kubernetes)
3. Wait for Docker and Kubernetes to start

### Step 5: Verify Installation

```powershell
# Run verification script
.\installation-check.ps1
```

Review the test results and follow any recommendations.

## Post-Installation Configuration

### Docker Desktop Kubernetes

If Kubernetes wasn't auto-enabled:
1. Open Docker Desktop
2. Navigate to Settings > Kubernetes
3. Check "Enable Kubernetes"
4. Click "Apply & Restart"

### UV Package Manager

If UV installation fails:
```cmd
pip install uv
```

### GitHub CLI Authentication

```cmd
gh auth login
```

## Troubleshooting

### Common Issues

**Winget not found:**
- Ensure Windows is up to date
- Install from Microsoft Store: "App Installer"
- Restart terminal/system

**Python/pip not in PATH:**
- Restart computer after installation
- Manually add Python to PATH via System Environment Variables

**Docker daemon not running:**
- Launch Docker Desktop
- Wait for initialization to complete
- Check Docker Desktop settings

**VS Code extensions not installing:**
- Restart computer to refresh PATH
- Install manually: `code --install-extension <extension-id>`

**WSL not working:**
- Enable WSL feature: `wsl --install`
- Restart computer
- Update WSL: `wsl --update`

### Log Files

Installation logs are saved with timestamp:
```
installation-log_YYYYMMDD_HHMMSS.txt
```

Test reports (with -Detailed flag):
```
LabTestReport_YYYYMMDD_HHMMSS.json
```

## System Requirements

- **OS:** Windows 10 (version 2004 or higher) or Windows 11
- **RAM:** 8 GB minimum (16 GB recommended)
- **Disk Space:** 50 GB free space recommended
- **Internet:** Stable broadband connection
- **Privileges:** Administrator access required

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

iomegak12

## Acknowledgments

- Microsoft for winget and VS Code
- Docker for Docker Desktop
- All open-source projects included in this setup
