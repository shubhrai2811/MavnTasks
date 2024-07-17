# Define the directory containing the PowerShell scripts
$scriptDirectory = "/media/prolevelnoob/Shubh/CodePlayground/mavn"

# Get all PowerShell scripts in the directory
$scripts = Get-ChildItem -Path $scriptDirectory -Filter *.ps1

# Function to check for script documentation
function Check-Documentation {
    param (
        [string]$scriptContent
    )
    if ($scriptContent -notmatch '<#.*?#>') {
        Write-Output "Warning: Script lacks documentation block."
    }
}

# Function to check for common errors and best practices
function Check-BestPractices {
    param (
        [string]$scriptContent
    )

    if ($scriptContent -match 'Write-Host') {
        Write-Output "Warning: Avoid using Write-Host, use Write-Output instead."
    }

    if ($scriptContent -notmatch 'Param\(') {
        Write-Output "Warning: Script lacks a Param block for parameter definition."
    }

    if ($scriptContent -match '\$global:') {
        Write-Output "Warning: Avoid using global variables, consider using scoped variables."
    }

    if ($scriptContent -match '\$ErrorActionPreference\s*=\s*\"Stop\"') {
        Write-Output "Warning: Consider using Try-Catch blocks for error handling instead of setting \$ErrorActionPreference."
    }
}

# Iterate through each script and perform checks
foreach ($script in $scripts) {
    Write-Output "Checking script: $($script.FullName)"

    $content = Get-Content -Path $script.FullName -Raw

    Check-Documentation -scriptContent $content
    Check-BestPractices -scriptContent $content

    Write-Output "---------------------------------------"
}

Write-Output "Quality assurance checks completed."
