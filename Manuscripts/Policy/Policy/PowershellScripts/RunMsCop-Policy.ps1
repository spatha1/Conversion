function WriteXmlToScreen ([xml]$xml)
{
    $StringWriter = New-Object System.IO.StringWriter;
    $XmlWriter = New-Object System.Xml.XmlTextWriter $StringWriter;
    $XmlWriter.Formatting = "indented";
    $xml.WriteTo($XmlWriter);
    $XmlWriter.Flush();
    $StringWriter.Flush();
    Write-Host $StringWriter.ToString();
}

Write-Output "Starting Policy MsCop....................."
Try
{

$fileName = "Task_XXXXX_MergeReport"

Powershell.exe -ExecutionPolicy RemoteSigned -File ".\MsCop\files\source\MsCop\CommandLine\MsCop.ps1" -manuscriptRoot ".\Policy\ManuScripts" -xslRoot ".\MsCop\files\source\MsCop" -outputRoot "C:\Temp\Policy" -MSCatalogPath ".\Policy\Shared\ManuScriptCatalog.xml" -asXml

Powershell.exe -ExecutionPolicy RemoteSigned -File ".\MsCop\files\source\MsCop\CommandLine\MsCopXmlMerge.ps1" -reviewFolder "C:\Temp\Policy\XML" -fileName "$fileName" 

 if (Test-path '.\Policy\MsCop Reports'){
	Copy-Item "C:\Temp\Policy\XML\$fileName.xml" ".\Policy\MsCop Reports"
}

Write-Output ""
if (Test-path '.\Policy\MsCop Reports'){
Write-Output "==>Policy Report file $fileName.xml added to Policy\MsCop Reports folder"
}
else{
Write-Output "==>Policy Report file $fileName.xml added to C:\Temp\Policy\ folder"
}

if (Test-path '.\Policy\MsCop Reports'){
	[xml]$xmlFinalReport = Get-Content -Path ".\Policy\MsCop Reports\$fileName.xml"
}
else{
	[xml]$xmlFinalReport = Get-Content -Path "C:\Temp\Policy\XML\$fileName.xml"
}

$errorCount = $xmlFinalReport.SelectNodes('//module').Count

if($errorCount -gt 0){    
	Write-Output "`n`nFAILURE: Policy Manuscript validation failed by MsCop rules, Please fix it`n"
	Write-Output "`t`t`t`t*******  ATTENTION:Error Details    *******`n"
	WriteXmlToScreen $xmlFinalReport
}
else{
      Write-Output "`n`nEXCELLENT: Report is clean, Nice work!" 
}

if($errorCount -gt 0){
    Write-Output "`n`n`n`n`n******************************** IGNORE EVERYTHING BELOW THIS *********************************************" 
	Write-Error "IGNORE THIS: This exception is for build team only."
	exit 1
}
}
Catch
{
	Write-Error $_.Exception.Message
	exit 1
}