<#
This script will look for all the XSLT files in a passed in folder and it's subfolders. For each, XSLT
transform file found:
1) the transform will be applied to a file in the corresponding location in the passed in root folder.
2) the file created will be copied over the original source file
#>
param(
    
    [Parameter(HelpMessage="Base folder for all XSLT transform files eg c:\DuckCreek\Policy\Carrier\deployment\configuration\policy")]
    $XSLTBaseFolder,   
    [Parameter(HelpMessage="Base folder for application containing configuration files to transform eg c:\DuckCreek\Policy")]
    $DCTRootFolder
)

"starting"
#Check for any files that do not exist in target folder
#if not there, copy the template config file.
Get-ChildItem $XSLTBaseFolder -Recurse -Filter *.template|ForEach-Object{

	"creating files"
	
    $cfgSubFolder  = $_.Directory.FullName -replace [Regex]::Escape($XSLTBaseFolder), ""

    #remove template extention from file name
    $TemplateFile = $_.Name.Replace(".template","")

	$srcCfgFilePath = "$DCTRootFolder$cfgSubFolder\$TemplateFile"
	$targetCfgFolder = "$DCTRootFolder$cfgSubFolder"

    Write-Output "Checking for file: $srcCfgFilePath"  
    
	#check if config file exists, if not, copy it.
    if (-not (Test-Path $srcCfgFilePath)){
        Write-Output "File does not exist. Copying."
        Copy-Item -Path $_.FullName -Destination "$targetCfgFolder\$TemplateFile"
    } else {
     Write-Output "File exists"    
    }

}

#Update config files
Get-ChildItem $XSLTBaseFolder -Recurse -Filter *.xslt|ForEach-Object{

    $relFolder = $_.Directory.FullName -replace [Regex]::Escape($XSLTBaseFolder), ""

    $cfgFile = $_.Name.Replace(".xslt","")

    $transCfgFilePath = $_.FullName.Replace(".xslt","")   

    $srcCfgFilePath = "$DCTRootFolder$relFolder\$cfgFile"

    $targetFolder = "$DCTRootFolder$relFolder"
    

    #remove previous transformed config file
    if (Test-Path $transCfgFilePath){
     Remove-Item $transCfgFilePath -Force -ErrorAction SilentlyContinue
    }

    #apply transforms to file
    try {
        Write-Output "Updating $transCfgFilePath"
        Write-Output "...Loading transform file $($_.FullName)"
        $sharedConfigTransform = New-Object System.Xml.Xsl.XslCompiledTransform
        $sharedConfigTransform.Load($_.FullName)
        $sharedConfigTransform.Transform($srcCfgFilePath, $transCfgFilePath)

        #remove blank lines
        (gc $transCfgFilePath) | ? {$_.trim() -ne "" } | set-content $transCfgFilePath

        #Copy the transformed config file over the source one
        Copy-Item $transCfgFilePath  $targetFolder -Force
        } catch {
            Write-Error "An error occurred:"
            Write-Error $_
    }    
}

"completed"
