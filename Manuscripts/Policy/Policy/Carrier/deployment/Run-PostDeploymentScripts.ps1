<#
    .SYNOPSIS
    This script runs immediately after the deployment but prior to Duck Creek Services startup


#>


Write-Output "Running Post Deployment Scripts..."

# get current folder
$curpath  = Split-Path -Parent $PSCommandPath 

# run configuration scripts

$PolicyFolder = "$($curpath)\..\.."

$TransformsFolder = "$($curpath)\configuration\Policy"

& "$($curpath)\configuration\transform-configs.ps1" -XSLTBaseFolder $TransformsFolder -DCTRootFolder $PolicyFolder

