# ----------------------------------------------------------
# Author:          damiancypcar
# Modified:        07.07.2023
# Version:         1.1
# Desc:            Update Terraform to latest version
# ----------------------------------------------------------
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '')]

# Update Terraform to latest version
Param (
    [switch]$help = $false
)

# All error stop the process
$ErrorActionPreference = "Stop"

$_TERRAFORM_NEW_VERSION = $null
$_TERRAFORM_BIN_PATH = "$env:USERPROFILE\AppData\Local\Programs\_bin"
# $_TERRAFORM_BIN_PATH = "$PWD\bin"


function Show-Help {
    Write-Output "Update Terraform to latest version"
    Write-Output ("`nUsage:  {0} [options]`n" -f (Get-PSCallStack)[1].Command)
    Write-Output "options:`n-h, -help`tshow help"
    break
}

function New-TemporaryDirectory {
    $parent = [System.IO.Path]::GetTempPath()
    [string]$name = [System.Guid]::NewGuid()
    $fullPath = New-Item -ItemType Directory -Path (Join-Path $parent $name)
    return $fullPath.FullName
}

function Get-TerraformVersion {
    if (-not (Test-Path -Path "$_TERRAFORM_BIN_PATH\terraform.exe")) {
        Write-Output "Terraform NOT found in $_TERRAFORM_BIN_PATH"
        $script:_TERRAFORM_CURR_VERSION = '-'
        $script:_TERRAFORM_NEW_VERSION = '1.5.2'
        return
    }

    $tfRawVersion = & $_TERRAFORM_BIN_PATH\terraform.exe --version
    $tfRawVersion = $tfRawVersion -match '(\d+\.)(\d+\.)(\*|\d+)' -split ' '
    $tfNewVersion = $tfRawVersion[3]
    if ($tfNewVersion) {
        $script:_TERRAFORM_NEW_VERSION = $tfNewVersion.TrimEnd('.')
        $script:_TERRAFORM_CURR_VERSION = $tfRawVersion[1].TrimStart('v')
    }
}

function Get-TerraformBinary {
    Write-Output "Downloading Terraform..."
    $tempDir = New-TemporaryDirectory
    Set-Location -Path $tempDir
    Write-Output "Temp dir: $tempDir"
    $dwnlURL = "https://releases.hashicorp.com/terraform/${_TERRAFORM_NEW_VERSION}/terraform_${_TERRAFORM_NEW_VERSION}_windows_amd64.zip"
    $outFile = "terraform_${_TERRAFORM_NEW_VERSION}_windows_amd64.zip"
    Invoke-WebRequest $dwnlURL -OutFile $outFile
    Expand-Archive -Path $outFile -DestinationPath $PWD

    Write-Output "Copying to $_TERRAFORM_BIN_PATH"
    Copy-Item -Path "$PWD\terraform.exe" -Destination "$_TERRAFORM_BIN_PATH\terraform.exe"
    
    Set-Location -Path $PSScriptRoot
}

function Main {
    Get-TerraformVersion
    if ($_TERRAFORM_NEW_VERSION) {
        Write-Output "Current version: $_TERRAFORM_CURR_VERSION"
        Write-Output "Update to $_TERRAFORM_NEW_VERSION available."
        $confirmation = Read-Host "`nAre you sure you want to proceed (y/N)?"
        if ($confirmation -eq 'y') {
            Get-TerraformBinary
            Write-Output "Done"
        } else {
            Write-Output "Exiting"
            break
        }
    } else {
        Write-Output "Terraform is up to date!"
    }
}

if ($help) {
    Show-Help
}else {
    Main
}
