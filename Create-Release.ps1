<#
.SYNOPSIS
    .
.DESCRIPTION
    Assuming semantic value X.Y.Z where X, Y and Z are numeric values
    Valid: 12.3.9, 0.1.1, 3.1.123151
    Invalid: 1.3.004, 1.01.3
.PARAMETER UpdateType
    Specify Major, Minor or Patch upgrade
.EXAMPLE
    C:\src\repo\Branch.ps1 -UpdateType Major
    C:\src\repo\Branch.ps1 -UpdateType Minor
    C:\src\repo\Branch.ps1 -UpdateType Patch
.NOTES
    Author: Emil Torp
    Date:   Jan 12, 2018
#>

[cmdletbinding()]
Param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$UpdateType
)

# Variables
$releaseFolder = "release" # double space because of '* ' in selected branch

# Check input
if ($UpdateType -ne "Major" -and $UpdateType -ne "Minor" -and $UpdateType -ne "Patch") {
    throw [System.ArgumentException] "$UpdateType not valid, please specify Major, Minor or Patch"
}

# Get all branches
$branches = git branch

# Get only releases and keep semantic value
$releases = $branches|Where-Object{$_ -like "  $releaseFolder/*"}
$releases = $releases -replace "  $releaseFolder/",""

[System.Collections.ArrayList]$semantics = @()
ForEach ($semanticStringValue in $releases) {
    # Split the semanticStringValue
    $semanticObj = $SemanticStringValue.Split(".",[StringSplitOptions]'RemoveEmptyEntries')

    # Create a new object with separated Major, Minor and Patch
    $obj = New-Object psobject
    Add-Member -InputObject $obj -MemberType NoteProperty -Name Major -Value $($semanticObj[0] -as [int])
    Add-Member -InputObject $obj -MemberType NoteProperty -Name Minor -Value $($semanticObj[1] -as [int])
    Add-Member -InputObject $obj -MemberType NoteProperty -Name Patch -Value $($semanticObj[2] -as [int])
    [void]$semantics.Add($obj)
}

# Sort the list by Major, Minor and then Patch. All descending
$semantics = $semantics | Sort-Object -Property @{Expression = {$_.Major}; Ascending = $false},  @{Expression = {$_.Minor}; Ascending = $false},  @{Expression = {$_.Patch}; Ascending = $false}

# Get the latest release
$latestRelease = $semantics[0]
$latestBranchName = "$releaseFolder/$($latestRelease.Major).$($latestRelease.Minor).$($latestRelease.Patch)"

Write-Output "Latest release: $latestBranchName"

# Update the release number depending on upgrade type
if ($UpdateType -eq "Major") {
    $latestRelease.Major = $latestRelease.Major + 1
    $latestRelease.Minor = 0
    $latestRelease.Patch = 0
} elseif ($UpdateType -eq "Minor") {
    $latestRelease.Minor = $latestRelease.Minor + 1
    $latestRelease.Patch = 0
} elseif ($UpdateType -eq "Patch") {
    $latestRelease.Patch = $latestRelease.Patch + 1
}

# Create the new branch name (including folder name)
$newBranchName = "$releaseFolder/$($latestRelease.Major).$($latestRelease.Minor).$($latestRelease.Patch)"

# Create the new branch
Write-Output "Creating new release: $newBranchName"
git branch $newBranchName

# Done
Write-Output "Release created!"