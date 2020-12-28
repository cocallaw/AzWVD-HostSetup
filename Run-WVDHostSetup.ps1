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
    Write-Host "5 - Join Machine to AD Domain"
    Write-Host "6 - Exit"
    $o = Read-Host -Prompt 'Please type the number of the option you would like to perform '
    return $o.ToString()
}
function Get-WVDAgentsFromWeb {
    New-Item -Path $WVDSetupBootPath -ItemType Directory -Force
    New-Item -Path $WVDSetupInfraPath -ItemType Directory -Force

    #Download WVD Agents From Internet 
    Invoke-WebRequest -Uri $BootURI -OutFile "$WVDSetupBootPath\Microsoft.RDInfra.RDAgentBootLoader.Installer-x64.msi" -UseBasicParsing
    Write-Host "Downloaded RDAgentBootLoader"
    Invoke-WebRequest -Uri $infraURI -OutFile "$WVDSetupInfraPath\Microsoft.RDInfra.RDAgent.Installer-x64.msi" -UseBasicParsing
    Write-Host "Downloaded RDInfra"
}
function Invoke-Option {
    param (
        [parameter (Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateLength(1, 1)]
        [ValidateRange(1, 6)]
        [Int]$userSelection
    )

    if ($userSelection -eq "1") {

        Get-WVDAgentsFromWeb
        Invoke-Option -userSelection (Get-Option)
    }
    elseif ($userSelection -eq "2") {
        New-Item -Path $WVDSetupFslgxPath -ItemType Directory -Force
    
        Invoke-WebRequest -Uri $fslgxURI -OutFile "$WVDSetupFslgxPath\FSLogix_Apps.zip" -UseBasicParsing
        Write-Host "Downloaded FSLogix"
    
        Write-Host "Expanding and cleaning up Fslogix.zip"
        Expand-Archive "$WVDSetupFslgxPath\FSLogix_Apps.zip" -DestinationPath "$WVDSetupFslgxPath" -ErrorAction SilentlyContinue
        Remove-Item "$WVDSetupFslgxPath\FSLogix_Apps.zip"

        Invoke-Option -userSelection (Get-Option)
    }
    elseif ($userSelection -eq "3") {
        #test path for install files
        Write-Host "Checking if WVD Agents are located at C:\WVDSetup\"
        $tpBoot = Test-Path -Path "$WVDSetupBootPath\Microsoft.RDInfra.RDAgentBootLoader.Installer-x64.msi"
        $tpInfra = Test-Path -Path "$WVDSetupInfraPath\Microsoft.RDInfra.RDAgent.Installer-x64.msi"

        if (!$tpBoot -or !$tpInfra) {
            #if they do not exist download
            Write-Host "WVD Agents were not found" -ForegroundColor Yellow -BackgroundColor Black
            Write-Host "Downloading most recent WVD Agents to C:\WVDSetup\"
            Get-WVDAgentsFromWeb
        }

        Write-Host "To perform the install a access key from the WVD host pool is needed"
        $wvdToken = Read-Host -Prompt 'Please provide the WVD access key you would like to use'
        Write-host "Install will use access key starting with" $wvdToken.Substring(0, 5) "and ending with" $wvdToken.Substring($wvdToken.Length - 5)

        $AgentBootServiceInstaller = (dir $WVDSetupBootPath\ -Filter *.msi | Select-Object).FullName
        $AgentInstaller = (dir $WVDSetupInfraPath\ -Filter *.msi | Select-Object).FullName

        Write-Host "Starting install of $AgentBootServiceInstaller"
        $bootloader_deploy_status = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $AgentBootServiceInstaller", "/quiet", "/qn", "/norestart", "/passive" -Wait -Passthru
        $sts = $bootloader_deploy_status.ExitCode
        Write-Host "Installing WVD Boot Loader complete. Exit code=$sts"

        Write-Host "Starting install of $AgentInstaller"
        $RegistrationToken = $wvdToken.Trim()
        $agent_deploy_status = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $AgentInstaller", "/quiet", "/qn", "/norestart", "/passive", "REGISTRATIONTOKEN=$RegistrationToken" -Wait -Passthru
        $sts = $agent_deploy_status.ExitCode
        Write-Host "Installation of WVD Infra Agent on VM Complete. Exit code=$sts"

        Invoke-Option -userSelection (Get-Option)
    }
    elseif ($userSelection -eq "4") {
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

        Invoke-Option -userSelection (Get-Option)
    }
    elseif ($userSelection -eq "5") {
        Write-host "Actions will be perfromed on this computer:" $env:COMPUTERNAME 
        Write-host "Joining the computer to the domain will result in a restart" -ForegroundColor Yellow -BackgroundColor Black
        $userDomain = Read-Host -Prompt 'What AD Domain do you want to join this computer to?'
        Write-Host "This process will join" $env:COMPUTERNAME "to the AD Domain" $userDomain
        $userConfirm = Read-Host -Prompt 'Is that correct? (y/n)' -ForegroundColor Yellow -BackgroundColor Black
        if (($userConfirm.ToLower()).Trim() -eq "n") {
            Write-Host "Canceling joing to the domain"
            Invoke-Option -userSelection (Get-Option)
        }
        else {
            Write-Host "Starting to domain join..."
            Add-Computer –domainname $userDomain.Trim() -restart
        }
    }
    elseif ($userSelection -eq "6") {
        #Exit
        break
    }
    else {
        Write-Host "You have selected an invalid option please select again."
        Invoke-Option -userSelection (Get-Option)
    }
}

try {
    Invoke-Option -userSelection (Get-Option)
}
catch {
    Write-Host "Something went wrong"
    Invoke-Option -userSelection (Get-Option)
}


