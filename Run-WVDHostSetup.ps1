#Common Variables
$bootURI = "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH"
$infraURI = "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv"
$fslgxURI = "https://aka.ms/fslogix_download"
$WVDSetupBootPath = "C:\WVDSetup\Boot"
$WVDSetupInfraPath = "C:\WVDSetup\Infra"
$WVDSetupFslgxPath =  "C:\WVDSetup\fslogix"

#User Selects Option 
#Shoudl convert to function for easy refrence, return number choosen
Write-Host "Welcome to the WVD Setup Script"
Write-Host "What would you like to do?"
Write-Host "1 - Download WVD Agents"
Write-Host "2 - Uinstall WVD Insfra Agent and Boot Loader"
$option = Read-Host -Prompt 'Please type the number of the option you would like to perform '
$option.ToString()

if ($option = "1") {
    New-Item -Path $WVDSetupBootPath -ItemType Directory -Force
    New-Item -Path $WVDSetupInfraPath -ItemType Directory -Force
    New-Item -Path $WVDSetupFslgxPath -ItemType Directory -Force
    
    #Download WVD Agents From Internet 
    Invoke-WebRequest -Uri $BootURI -OutFile "$WVDSetupBootPath\Microsoft.RDInfra.RDAgentBootLoader.Installer-x64.msi" 
    Write-Host "Downloaded RDAgentBootLoader"
    Invoke-WebRequest -Uri $infraURI -OutFile "$WVDSetupInfraPath\Microsoft.RDInfra.RDAgent.Installer-x64.msi"
    Write-Host "Downloaded RDInfra"
    Invoke-WebRequest -Uri $fslgxURI -OutFile "$WVDSetupFslgxPath\FSLogix_Apps.zip"
    Write-Host "Downloaded FSLogix"
    
    Write-Host "Expanding and cleaning up Fslogix.zip"
    Expand-Archive "$WVDSetupFslgxPath\FSLogix_Apps.zip" -DestinationPath "$WVDSetupFslgxPath" -ErrorAction SilentlyContinue
    Remove-Item "$WVDDeployBasePath\FSLogix_Apps.zip"
}
else {
    Write-Host "You have selected an invalid option please select again."
}
