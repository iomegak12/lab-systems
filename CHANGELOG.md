# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `install-lab-software-otlp.ps1` - OTLP / Observability lab installer: base lab software plus Temurin JDK 21, Maven, OpenTelemetry Java agent, jq, curl, Grafana k6, Java/Docker/REST Client VS Code extensions, and pre-pulled Docker images for OTel Collector (contrib), telemetrygen, Prometheus, Grafana, Loki, Tempo and Jaeger
- `-ImagesOnly` switch on the OTLP installer to (re)pull images after a reboot
- `otlp-images.psd1` - pinned image tags and Java agent version, used by both scripts
- `installation-check.ps1 -Otlp` - verifies the OTLP lab software and images
- Initial release of lab systems environment setup scripts
- `install-lab-software.cmd` - Automated installation script
- `installation-check.ps1` - Verification and testing script
- Support for Windows 10/11
- Automatic winget installation on Windows 10
- Docker Desktop Kubernetes enablement
- Multipass installation
- 16 VS Code extensions auto-installation
- WSL and Ubuntu installation
- UV Python package manager installation via pip
- Detailed logging for installations and tests
- JSON export for detailed test reports
- Color-coded test results
- System information reporting
- Actionable recommendations

### Software Components
- Python 3.12
- Node.js (latest LTS)
- Git
- GitHub CLI
- Docker Desktop
- kubectl
- Visual Studio Code
- Google Chrome
- UV package manager
- WSL with Ubuntu
- Winget (on Windows 10)
- PowerShell (latest version)
- Multipass

### VS Code Extensions
- Remote - Containers
- GitHub Copilot
- GitHub Copilot Chat
- Jupyter suite (core, cell tags, keymap, renderers, slideshow)
- Markdown Preview Enhanced
- Pylance
- Python
- Python Debugger
- Rainbow CSV
- SQLite Viewer
- WSL
- YAML

### Documentation
- Comprehensive README.md
- MIT LICENSE
- CONTRIBUTING.md guidelines
- .gitignore for common patterns
- CHANGELOG.md for version tracking

## [1.0.0] - 2025-12-04

### Initial Release
- First stable release of lab systems environment setup scripts
