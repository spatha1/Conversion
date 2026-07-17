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

Write-Output "Starting Billing MsCop....................."
Try
{

$fileName = "Task_XXXXX_MergeReport"

Powershell.exe -ExecutionPolicy RemoteSigned -File  ".\MsCop\files\source\MsCop\CommandLine\MsCop.ps1" -manuscriptRoot ".\Billing\ManuScripts" -xslRoot ".\MsCop\files\source\MsCop" -outputRoot "C:\Temp\Billing" -MSCatalogPath ".\Billing\Shared\ManuScriptCatalog.xml" -asXml

Powershell.exe -ExecutionPolicy RemoteSigned -File ".\MsCop\files\source\MsCop\CommandLine\MsCopXmlMerge.ps1" -reviewFolder "C:\Temp\Billing\XML" -fileName "$fileName"

if (Test-path '.\Billing\MsCop Reports'){
	Copy-Item "C:\Temp\Billing\XML\$fileName.xml" ".\Billing\MsCop Reports"
}

Write-Output ""
if (Test-path '.\Billing\MsCop Reports'){
Write-Output "==>Billing Report file $fileName.xml added to Billing\MsCop Reports folder"
}
else{
Write-Output "==>Billing Report file $fileName.xml added to C:\Temp\Billing\ folder"
}

if (Test-path '.\Billing\MsCop Reports'){
	[xml]$xmlFinalReport = Get-Content -Path ".\Billing\MsCop Reports\$fileName.xml"
}
else{
	[xml]$xmlFinalReport = Get-Content -Path "C:\Temp\Billing\XML\$fileName.xml"
}

$errorCount = $xmlFinalReport.SelectNodes('//module').Count

if($errorCount -gt 0){    
	Write-Output "`n`nFAILURE: Billing Manuscript validation failed by MsCop rules, Please fix it`n"
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