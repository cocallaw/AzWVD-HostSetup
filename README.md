# WVD Host Multitool Script

To run this PowerShell Script on your WVD Host VM run the command below - 

`Invoke-Expression $(Invoke-WebRequest -uri aka.ms/wvdhostps -UseBasicParsing).Content`

or the shorthand version 

`iwr -useb aka.ms/wvdhostps | iex`

To download a local copy of the latest version of the script run the command below - 

`Invoke-WebRequest -Uri aka.ms/wvdhostps -OutFile Run-WVDHostSetup.ps1`

The WVD Host Multitool Script provides the ability to perform basic WVD Host configuration operations to simplify setup, testing and troubleshooting with WVD Host VMs. 

![PowerShell Screenshot](/images/wvdhostpsscreenshot01.png)

### Currently the WVD Host Multitool provides the option to perform the following tasks as of January 5, 2020

- Download WVD Agents
- Download FSLogix 
- Install WVD Infra Agent and Boot Loader
- Uninstall WVD Infra Agent and Boot Loader
- Install FSLogix
- Uninstall FSLogix
- Join VM to Windows AD Domain

### Features in development and testing - 

- Checking the values of FSLogix Registry Keys (Enable and VHDLocations)
- Setting FSlogix Registry Keys (Enable and VHDLocations)
- Download latest GPU drivers based on type (Intel or AMD)
- Install latest GPU drivers on VM based on type (Intel or AMD)

If you have an idea for a new feature or enhancements on an existing request feel free to open an [Issue](https://github.com/cocallaw/AzWVD-HostSetup/issues) or open a [Pull Request](https://github.com/cocallaw/AzWVD-HostSetup/pulls)
