# Define the Git repository path
$repoPath = "/media/prolevelnoob/Shubh/CodePlayground/45DayChallenge" # Change this to your repository path

# Ensure the script is running in the correct directory
Set-Location -Path $repoPath

# Function to handle errors
function Write-ErrorCustom {
    param (
        [string]$message
    )
    Write-Host "Error: $message" -ForegroundColor Red
    exit 1
}

# Check if git is installed
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-ErrorCustom "Git is not installed. Please install Git to use this script."
}

# Get the changes in the working directory
$changes = git status --porcelain
if ($LASTEXITCODE -ne 0) {
    Write-ErrorCustom "Failed to retrieve Git status."
}

# If no changes detected, exit
if (-not $changes) {
    Write-ErrorCustom "No changes detected in the working directory."
}

# Function to determine primary components affected
function Get-Components {
    param (
        [string[]]$filesChanged
    )
    $components = @()
    foreach ($file in $filesChanged) {
        $component = $file -split '/' | Select-Object -First 1
        if (-not $components.Contains($component)) {
            $components += $component
        }
    }
    return $components
}

# Get the list of changed files
$changedFiles = $changes | ForEach-Object { $_.Substring(3) }

# Determine primary components affected
$componentsAffected = Get-Components -filesChanged $changedFiles

# Get the diffs for the changed files
$diffs = git diff --cached

# Generate the commit message template
$commitTemplate = @"
# Commit Message Template
# -----------------------
# Component(s): $($componentsAffected -join ', ')
# 
# Brief Description: (Provide a concise description of the changes)
# 
# Detailed Description:
# - (Explain the changes in detail)
# 
# Code Changes:
$diffs
# 
# Related Issues: (List related issues or tickets, if any)
# 
# Additional Notes: (Any additional information)
"@

# Display the commit message template
Write-Host $commitTemplate

# Prompt the user to fill out the commit message
$briefDesc = Read-Host "Brief Description"
$detailedDesc = Read-Host "Detailed Description"
$relatedIssues = Read-Host "Related Issues"
$additionalNotes = Read-Host "Additional Notes"

# Enforce commit message conventions
if ($briefDesc.Length -gt 50) {
    Write-ErrorCustom "Brief Description should not exceed 50 characters."
}
if ($detailedDesc.Length -gt 72) {
    Write-ErrorCustom "Detailed Description should not exceed 72 characters per line."
}

# Assemble the final commit message
$finalMessage = @"
Component(s): $($componentsAffected -join ', ')

Brief Description: $briefDesc

Detailed Description:
$detailedDesc

Code Changes:
$diffs

Related Issues: $relatedIssues

Additional Notes: $additionalNotes
"@

# Display the final commit message for confirmation
Write-Host "`nFinal Commit Message:"
Write-Host "----------------------"
Write-Host $finalMessage

# Ask for confirmation before committing
$confirmCommit = Read-Host "Do you want to proceed with the commit? (y/n)"
if ($confirmCommit -ne 'y') {
    Write-ErrorCustom "Commit aborted by user."
}

# Commit the changes with the generated commit message
git commit -m $finalMessage
if ($LASTEXITCODE -ne 0) {
    Write-ErrorCustom "Failed to commit changes."
}

Write-Host "Changes committed successfully." -ForegroundColor Green
