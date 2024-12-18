# PowerShell script for VMware Host and VM Security Hardening
# Prerequisites: VMware PowerCLI module installed

# Connect to vCenter server
$vcServer = "vcenter.example.com"
$vcUsername = "administrator@vsphere.local"
$vcPassword = "password"
$esxiHostName = "esxi-host.example.com"  # Name of the ESXi host to apply security hardening
$reportPath = "C:\Security_Hardening_Reports"  # Path where the report will be saved

# Connect to vCenter
Connect-VIServer -Server $vcServer -User $vcUsername -Password $vcPassword

# Create report file
$reportFile = "$reportPath\Security_Hardening_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
New-Item -Path $reportFile -ItemType File -Force
Add-Content -Path $reportFile -Value "VMware Host and VM Security Hardening Report - $(Get-Date)"
Add-Content -Path $reportFile -Value "--------------------------------------"

# Function to disable unnecessary services on ESXi host
function Disable-ESXiUnnecessaryServices {
    Write-Host "Disabling unnecessary services on host: $esxiHostName"
    $unnecessaryServices = @("snmpd", "ntpd", "telnet")  # Example list of unnecessary services
    foreach ($service in $unnecessaryServices) {
        Set-VMHostService -VMHost $esxiHostName -Service $service -Policy "Off" -Confirm:$false
        Add-Content -Path $reportFile -Value "Disabled service: $service"
        Write-Host "Disabled service: $service"
    }
}

# Function to configure firewall settings on ESXi host
function Configure-ESXiFirewall {
    Write-Host "Configuring firewall settings for host: $esxiHostName"
    $firewallRules = @(
        @{Name="Allow SSH" ; Enabled=$true},
        @{Name="Allow HTTPS" ; Enabled=$true}
    )
    foreach ($rule in $firewallRules) {
        Set-VMHostFirewall -VMHost $esxiHostName -Name $rule.Name -Enabled $rule.Enabled -Confirm:$false
        Add-Content -Path $reportFile -Value "Configured firewall rule: $($rule.Name) - Enabled: $($rule.Enabled)"
        Write-Host "Configured firewall rule: $($rule.Name) - Enabled: $($rule.Enabled)"
    }
}

# Function to apply security patches on ESXi host
function Apply-ESXiSecurityPatches {
    Write-Host "Applying security patches to host: $esxiHostName"
    $host = Get-VMHost -Name $esxiHostName
    $patches = Get-VMHostPatch -VMHost $host | Where-Object {$_.Status -eq "Needed"}
    if ($patches) {
        Install-VMHostPatch -VMHost $esxiHostName -Patch $patches -Confirm:$false
        Add-Content -Path $reportFile -Value "Applied security patches: $($patches | ForEach-Object {$_.Name})"
        Write-Host "Applied security patches."
    } else {
        Write-Host "No security patches required."
        Add-Content -Path $reportFile -Value "No security patches required."
    }
}

# Function to disable unnecessary services on VMs
function Disable-VMUnnecessaryServices {
    Write-Host "Disabling unnecessary services on all VMs in the host"
    $vms = Get-VM -VMHost $esxiHostName
    foreach ($vm in $vms) {
        $unnecessaryServices = @("telnet", "ftp")
        foreach ($service in $unnecessaryServices) {
            # Example of disabling services, modify for actual VM OS
            Get-Service -VM $vm -Name $service | Stop-Service -Confirm:$false
            Add-Content -Path $reportFile -Value "Disabled service: $service on VM: $($vm.Name)"
            Write-Host "Disabled service: $service on VM: $($vm.Name)"
        }
    }
}

# Function to apply security patches on VMs
function Apply-VMSecurityPatches {
    Write-Host "Applying security patches to all VMs in the host"
    $vms = Get-VM -VMHost $esxiHostName
    foreach ($vm in $vms) {
        # Example of applying security patches, modify according to VM OS and patching system
        # Assuming VMware Tools are installed and OS-based updates are managed
        # You may use Invoke-VMScript to run patch management commands on the VM OS
        Write-Host "Applying security patches to VM: $($vm.Name)"
        Add-Content -Path $reportFile -Value "Applied security patches to VM: $($vm.Name)"
    }
}

# Run the security hardening actions
Disable-ESXiUnnecessaryServices
Configure-ESXiFirewall
Apply-ESXiSecurityPatches
Disable-VMUnnecessaryServices
Apply-VMSecurityPatches

# Disconnect from vCenter
Disconnect-VIServer -Server $vcServer -Confirm:$false

Write-Host "Security hardening completed. Report saved to: $reportFile"
