# Function to handle errors
function Handle-Error {
    param (
        [string]$Message
    )
    Write-Host "Error: $Message" -ForegroundColor Red
    exit 1
}

# Function to check if a command exists
function Check-Command {
    param (
        [string]$Command
    )
    if (-not (Get-Command $Command -ErrorAction SilentlyContinue)) {
        Handle-Error "$Command is required but not installed."
    }
}

# Function to detect Windows version
function Get-WindowsVersion {
    $osVersion = [System.Environment]::OSVersion.Version

    if ($osVersion.Major -eq 10 -and $osVersion.Build -ge 22000) {
        return "Windows 11"
    } elseif ($osVersion.Major -eq 10 -and $osVersion.Build -ge 14393) {
        return "Windows 10"
    } elseif ($osVersion.Major -eq 6 -and $osVersion.Minor -eq 3) {
        return "Windows 8.1"
    } elseif ($osVersion.Major -eq 6 -and $osVersion.Minor -eq 2) {
        return "Windows 8"
    } elseif ($osVersion.Major -eq 6 -and $osVersion.Minor -eq 1) {
        return "Windows 7"
    } else {
        Handle-Error "Unsupported Windows version."
    }
}

# Function to install Chocolatey
function Get-Chocolatey {
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "Chocolatey: installing"
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) || Handle-Error "Chocolatey: install failed."

        # Refresh the environment to include the choco command
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine) + ";C:\ProgramData\chocolatey\bin"   #update this if already installed
        [Environment]::SetEnvironmentVariable("Path", $env:Path, [EnvironmentVariableTarget]::Process)
    } else {
        # Ensure the choco command is available in the current session
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine) + ";C:\ProgramData\chocolatey\bin"    #update this if already installed
        [Environment]::SetEnvironmentVariable("Path", $env:Path, [EnvironmentVariableTarget]::Process)
    }
}

# Function to install packages using Chocolatey
function Install-Packages {
    param (
        [string[]]$Packages
    )
    foreach ($package in $Packages) {
        Write-Host "Installing $package..."
        choco install $package -y || Handle-Error "Failed to install $package."
    }
}

# Function to configure services
function Configure-Services {
    Write-Host "Configuring services..."
    # Add service configuration commands here
}

# Function to set up test databases
function Setup-TestDatabases {
    Write-Host "Setting up test databases..."
    # Install MySQL
    choco install mysql -y || Handle-Error "Failed to install MySQL."
    & 'C:\Program Files\MySQL\MySQL Server 8.0\bin\mysqld' --initialize-insecure --user=mysql || Handle-Error "MySQL : initialization failed."

    # Install PostgreSQL
    choco install postgresql -y || Handle-Error "Failed to install PostgreSQL."
    & 'C:\Program Files\PostgreSQL\12\bin\initdb' -D 'C:\Program Files\PostgreSQL\12\data' || Handle-Error "PostgreSQL: initialization failed."
}

# Main function to orchestrate setup
function Main {
    # Check for admin permissions
    if ($IsWindows) {
        if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
            Handle-Error "This script must be run as an Administrator."
        }

        # Detect Windows version
        $windowsVersion = Get-WindowsVersion
        Write-Host "Detected Windows version: $windowsVersion"

        # Perform setup steps
        Get-Chocolatey
        Install-Packages -Packages @("git", "nodejs", "python", "visualstudiocode")
        Configure-Services
        Setup-TestDatabases
    } else {
        Handle-Error "This script is intended to run on Windows only."
    }

    Write-Host "Development environment setup complete."
}

# Execute the main function
Main
