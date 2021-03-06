#region variables
$bootURI = "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH"
$infraURI = "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv"
$fslgxURI = "https://aka.ms/fslogix_download"
$WVDSetupBootPath = "C:\WVDSetup\Boot"
$WVDSetupInfraPath = "C:\WVDSetup\Infra"
$WVDSetupFslgxPath = "C:\WVDSetup\fslogix"
$FSLInstallerEXE = "$WVDSetupFslgxPath\x64\Release\FSLogixAppsSetup.exe"
#endregion vatiables

#region functions
function Get-Option {
    Write-Host "What would you like to do?"
    Write-Host "1 - Download WVD Agents"
    Write-Host "2 - Download FSLogix"    
    Write-Host "3 - Install WVD Infra Agent and Boot Loader"
    Write-Host "4 - Uninstall WVD Infra Agent and Boot Loader"
    Write-Host "5 - Install FSLogix"
    Write-Host "6 - Uninstall FSLogix"
    Write-Host "7 - Join VM to Windows AD Domain"
    Write-Host "8 - Exit"
    $o = Read-Host -Prompt 'Please type the number of the option you would like to perform '
    return ($o.ToString()).Trim()
}
function Get-WVDAgentsFromWeb {
    New-Item -Path $WVDSetupBootPath -ItemType Directory -Force
    New-Item -Path $WVDSetupInfraPath -ItemType Directory -Force
    #Invoke-WebRequest -Uri $BootURI -OutFile "$WVDSetupBootPath\Microsoft.RDInfra.RDAgentBootLoader.Installer-x64.msi" -UseBasicParsing
    Start-BitsTransfer -Source $BootURI -Destination "$WVDSetupBootPath\Microsoft.RDInfra.RDAgentBootLoader.Installer-x64.msi"
    Write-Host "Downloaded RDAgentBootLoader to $WVDSetupBootPath"
    #Invoke-WebRequest -Uri $infraURI -OutFile "$WVDSetupInfraPath\Microsoft.RDInfra.RDAgent.Installer-x64.msi" -UseBasicParsing
    Start-BitsTransfer -Source $infraURI -Destination "$WVDSetupInfraPath\Microsoft.RDInfra.RDAgent.Installer-x64.msi"
    Write-Host "Downloaded RDInfra to $WVDSetupInfraPath"
}
function Get-FSLogixAgentFromWeb {
    New-Item -Path $WVDSetupFslgxPath -ItemType Directory -Force
    #Invoke-WebRequest -Uri $fslgxURI -OutFile "$WVDSetupFslgxPath\FSLogix_Apps.zip" -UseBasicParsing
    Start-BitsTransfer -Source $fslgxURI -Destination "$WVDSetupFslgxPath\FSLogix_Apps.zip"
    Write-Host "Downloaded FSLogix to $WVDSetupFslgxPath"
    Write-Host "Expanding and cleaning up Fslogix.zip"
    Expand-Archive "$WVDSetupFslgxPath\FSLogix_Apps.zip" -DestinationPath "$WVDSetupFslgxPath" -ErrorAction SilentlyContinue
    Remove-Item "$WVDSetupFslgxPath\FSLogix_Apps.zip"
}
function Invoke-Option {
    param (
        [parameter (Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateLength(1, 1)]
        [string]$userSelection
    )

    if ($userSelection -eq "1") {
        #1 - Download WVD Agents
        Get-WVDAgentsFromWeb
        Invoke-Option -userSelection (Get-Option)
    }
    elseif ($userSelection -eq "2") {
        #2 - Download FSLogix
        Get-FSLogixAgentFromWeb
        Invoke-Option -userSelection (Get-Option)
    }
    elseif ($userSelection -eq "3") {
        #3 - Install WVD Infra Agent and Boot Loader
        Write-Host "Checking if WVD Agents are located at C:\WVDSetup\"
        $tpBoot = Test-Path -Path "$WVDSetupBootPath\Microsoft.RDInfra.RDAgentBootLoader.Installer-x64.msi"
        $tpInfra = Test-Path -Path "$WVDSetupInfraPath\Microsoft.RDInfra.RDAgent.Installer-x64.msi"
        if (!$tpBoot -or !$tpInfra) {
            #If WVD agents not found download current versions
            Write-Host "WVD Agents were not found" -ForegroundColor Yellow -BackgroundColor Black
            Write-Host "Downloading most recent WVD Agents to C:\WVDSetup\"
            Get-WVDAgentsFromWeb
        }
        Write-Host "To perform the install a registration key from the WVD host pool is needed"
        $wvdToken = Read-Host -Prompt 'Please provide the WVD registration key you would like to use'
        Write-host "Install will use registration  key starting with" $wvdToken.Substring(0, 5) "and ending with" $wvdToken.Substring($wvdToken.Length - 5)
        $AgentBootServiceInstaller = (Get-ChildItem $WVDSetupBootPath\ -Filter *.msi | Select-Object).FullName
        $AgentInstaller = (Get-ChildItem $WVDSetupInfraPath\ -Filter *.msi | Select-Object).FullName
        #WVD Boot Loader Install
        Write-Host "Starting install of $AgentBootServiceInstaller"
        $bootloader_deploy_status = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $AgentBootServiceInstaller", "/quiet", "/qn", "/norestart", "/passive" -Wait -Passthru
        $sts = $bootloader_deploy_status.ExitCode
        Write-Host "Installing WVD Boot Loader complete. Exit code=$sts"
        #WVD Infra Agent Install
        Write-Host "Starting install of $AgentInstaller"
        $RegistrationToken = $wvdToken.Trim()
        $agent_deploy_status = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $AgentInstaller", "/quiet", "/qn", "/norestart", "/passive", "REGISTRATIONTOKEN=$RegistrationToken" -Wait -Passthru
        $sts = $agent_deploy_status.ExitCode
        Write-Host "Installation of WVD Infra Agent on VM Complete. Exit code=$sts"
        Invoke-Option -userSelection (Get-Option)
    }
    elseif ($userSelection -eq "4") {
        #4 - Uninstall WVD Infra Agent and Boot Loader
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
        #5 -Install FSLogix
        Write-Host "Checking if FSLogix Agent is located at C:\WVDSetup\fslogix"
        $tpFSL = Test-Path $FSLInstallerEXE
        if (!$tpFSL) {
            Write-Host "FSLogix Agent was not found" -ForegroundColor Yellow -BackgroundColor Black
            Write-Host "Downloading most recent FSlogix Agent to C:\WVDSetup\fslogix"
            Get-FSLogixAgentFromWeb
        }
        Write-Host "Installing FSLogix Agent on $env:COMPUTERNAME"
        & $FSLInstallerEXE -install
        Write-Host "FSLogix Installer Has Completed"
        Invoke-Option -userSelection (Get-Option)
    }
    elseif ($userSelection -eq "6") {
        #6 -Uninstall FSLogix
        Write-Host "Checking if FSLogix Agent is located at C:\WVDSetup\fslogix in order to perform operations"
        $tpFSL = Test-Path $FSLInstallerEXE
        if (!$tpFSL) {
            Write-Host "FSLogix Agent was not found" -ForegroundColor Yellow -BackgroundColor Black
            Write-Host "Downloading most recent FSlogix Agent to C:\WVDSetup\fslogix"
            Get-FSLogixAgentFromWeb
        }
        Write-Host "Uninstalling FSLogix Agent on $env:COMPUTERNAME"
        & $FSLInstallerEXE -uninstall
        Write-Host "FSLogix Uninstall Has Completed"
        Invoke-Option -userSelection (Get-Option)
    }
    elseif ($userSelection -eq "7") {
        #7 - Join VM to Windows AD Domain
        try {
            $DomainName = Read-Host -Prompt 'Windows AD Domain to Join'
            $Creds = Get-Credential -Message "Credentials To Join VM to $DomainName"
            $OUyn = Read-Host -Prompt "Do you want to specify an OUPath to place the computer object in AD? (y/n)"
            if (($OUyn.Trim()).ToLower() -eq "y") {
                Write-Host "Please provide an OUPath in the format - OU=testOU,DC=domain,DC=Domain,DC=com"
                $OUPath = Read-Host -Prompt "OUPath"
                Write-Host "This process will join" $env:COMPUTERNAME "to the Windows AD Domain" $DomainName
                Write-Host "The OUPath that will be used is" $OUPath
                Write-host "Joining the computer to the domain will require a restart" -ForegroundColor Yellow 
                $userConfirm = Read-Host -Prompt 'Is the above information correct? (y/n)'
                if (($userConfirm.ToLower()).Trim() -eq "n") {
                    Write-Host "Canceling joining to the domain"
                    Invoke-Option -userSelection (Get-Option)
                }
                elseif (($userConfirm.ToLower()).Trim() -eq "y") {
                    Write-Host "Starting to domain join..."
                    Add-Computer -DomainName $DomainName.Trim() -Credential $Creds -OUPath $OUPath.Trim() -Force
                } 
                else {
                    Write-Host "Invalid input canceling joining the domain"
                    Invoke-Option -userSelection (Get-Option)
                }
            }
            elseif (($OUyn.Trim()).ToLower() -eq "n") {
                Write-Host "This process will join" $env:COMPUTERNAME "to the Windows AD Domain" $DomainName
                Write-host "Joining the computer to the domain will require a restart" -ForegroundColor Yellow
                $userConfirm = Read-Host -Prompt 'Is the above information correct? (y/n)'
                if (($userConfirm.ToLower()).Trim() -eq "n") {
                    Write-Host "Canceling joining to the domain"
                    Invoke-Option -userSelection (Get-Option)
                }
                elseif (($userConfirm.ToLower()).Trim() -eq "y") {
                    Write-Host "Starting to domain join..."
                    Add-Computer -DomainName $DomainName -Credential $Creds -Force
                } 
                else {
                    Write-Host "Invalid input canceling joining the domain"
                    Invoke-Option -userSelection (Get-Option)
                }              
            }
            else {
                Write-Host "Invalid selection" -ForegroundColor Yellow -BackgroundColor Black
                Invoke-Option -userSelection (Get-Option)
            }           
        }
        catch {
            $error[0] | format-list -force  #print more detail reason for failure   
            Invoke-Option -userSelection (Get-Option)
        }
    }
    elseif ($userSelection -eq "8") {
        #8 -Exit
        break
    }
    else {
        Write-Host "You have selected an invalid option please select again." -ForegroundColor Red -BackgroundColor Black
        Invoke-Option -userSelection (Get-Option)
    }
}
#endregion functions

#region main
Write-Host "Welcome to the WVD Host Multitool Script"
try {
    Invoke-Option -userSelection (Get-Option)
}
catch {
    Write-Host "Something went wrong" -ForegroundColor Yellow -BackgroundColor Black
    Invoke-Option -userSelection (Get-Option)
}
#endregion main