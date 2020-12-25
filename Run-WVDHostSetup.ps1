#Common Variables
$bootURI = "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH"
$infraURI = "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv"
$fslgxURI = "https://aka.ms/fslogix_download"
$WVDSetupBootPath = "C:\WVDSetup\Boot"
$WVDSetupInfraPath = "C:\WVDSetup\Infra"
$WVDSetupFslgxPath = "C:\WVDSetup\fslogix"

#User Selects Option 
#Should convert to function for easy refrence, return number choosen
Write-Host "Welcome to the WVD Setup Script"

function Get-Option {
    Write-Host "What would you like to do?"
    Write-Host "1 - Download WVD Agents"
    Write-Host "2 - Download FSLogix"    
    Write-Host "3 - Install WVD Infra Agent and Boot Loader"
    Write-Host "4 - Uninstall WVD Infra Agent and Boot Loader"
    Write-Host "5 - Exit"
    $o = Read-Host -Prompt 'Please type the number of the option you would like to perform '
    return $o.ToString()
}

function Run-Option($option) {
    if ($option = "1") {
        New-Item -Path $WVDSetupBootPath -ItemType Directory -Force
        New-Item -Path $WVDSetupInfraPath -ItemType Directory -Force
    
        #Download WVD Agents From Internet 
        Invoke-WebRequest -Uri $BootURI -OutFile "$WVDSetupBootPath\Microsoft.RDInfra.RDAgentBootLoader.Installer-x64.msi" 
        Write-Host "Downloaded RDAgentBootLoader"
        Invoke-WebRequest -Uri $infraURI -OutFile "$WVDSetupInfraPath\Microsoft.RDInfra.RDAgent.Installer-x64.msi"
        Write-Host "Downloaded RDInfra"
    }
    if ($option = "2") {
        New-Item -Path $WVDSetupFslgxPath -ItemType Directory -Force
    
        Invoke-WebRequest -Uri $fslgxURI -OutFile "$WVDSetupFslgxPath\FSLogix_Apps.zip"
        Write-Host "Downloaded FSLogix"
    
        Write-Host "Expanding and cleaning up Fslogix.zip"
        Expand-Archive "$WVDSetupFslgxPath\FSLogix_Apps.zip" -DestinationPath "$WVDSetupFslgxPath" -ErrorAction SilentlyContinue
        Remove-Item "$WVDSetupFslgxPath\FSLogix_Apps.zip"
    }
    if ($option = "3") {
        
    }
    if ($option = "4") {
        Write-Host "Uninstalling any previous versions of the WVD RDInfra Agent on VM"
        $RDInfraApps = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -eq "Remote Desktop Services Infrastructure Agent" }
        foreach ($app in $RDInfraApps) {
            Write-Host "Uninstalling WVD RDInfra Agent $app.Version"
            $app.Uninstall()
        }
        Write-Host "Uninstalling any previous versions of WVD RDAgentBootLoader on VM"
        $RDInfraApps = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -eq "Remote Desktop Agent Boot Loader" }
        foreach ($app in $RDInfraApps) {
            Write-Host "Uninstalling RDAgentBootLoader $app.Version"
            $app.Uninstall()
        }
    }
    if ($option = "5") {
        break
    }
    else {
        Write-Host "You have selected an invalid option please select again."
    }
}


$option = Get-Option
Run-Option -option $option


