# WVD Host Multitool Script

To run this PowerShell Script on your WVD Host VM you can run the command below - 

`Invoke-Expression $(Invoke-WebRequest -uri aka.ms/wvdhostps -UseBasicParsing).Content`

The WVD Host Multitool Script provides the ability to perform basic WVD Host configuration operation to simplify setup, testing and troubleshooting with WVD Host VMs. 

Currently the WVD Host Multitool performs that following operations as of January 4, 2020

- Download WVD Agents
- Download FSLogix 
- Install WVD Infra Agent and Boot Loader
- Uninstall WVD Infra Agent and Boot Loader
- Join VM to Windows AD Domain

Features in development and testing - 

- Installation of FSLogix
- Checking the values of FSLogix Registry Keys (Enable and VHDLocations)
- Setting FSlogix Registry Keys (Enable and VHDLocations)

Ig you have an idea for a new feature or enhancements on an existing request feel free to open an [Issue](https://github.com/cocallaw/AzWVD-HostSetup/issues) or open a [Pull Request](https://github.com/cocallaw/AzWVD-HostSetup/pulls)