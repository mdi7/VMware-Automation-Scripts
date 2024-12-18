# PowerShell script for VMware VM Customization for Different Environments
# Prerequisites: VMware PowerCLI module installed

# Connect to vCenter server
$vcServer = "vcenter.example.com"
$vcUsername = "administrator@vsphere.local"
$vcPassword = "password"
$vmName = "VM-to-customize"  # Name of the VM to customize
$environmentType = "development"  # Environment type: development, staging, production

# Define customizations for each environment
$customizations = @{
    "development" = @{
        CPU = 2
        MemoryGB = 4
        NetworkName = "Dev-Network"
    }
    "staging" = @{
        CPU = 4
        MemoryGB = 8
        NetworkName = "Staging-Network"
    }
    "production" = @{
        CPU = 8
        MemoryGB = 16
        NetworkName = "Prod-Network"
    }
}

# Check if the environment type exists in the customization hashtable
if ($customizations.ContainsKey($environmentType)) {
    # Get the custom settings for the selected environment
    $envSettings = $customizations[$environmentType]

    # Connect to vCenter
    Connect-VIServer -Server $vcServer -User $vcUsername -Password $vcPassword

    # Get the VM to customize
    $vm = Get-VM -Name $vmName

    if ($vm) {
        # Customize the VM based on the environment
        Write-Host "Customizing VM $vmName for the $environmentType environment..."

        # Set CPU and Memory
        Set-VM -VM $vm -NumCpu $envSettings.CPU -MemoryGB $envSettings.MemoryGB -Confirm:$false
        Write-Host "Set CPU to $($envSettings.CPU) and Memory to $($envSettings.MemoryGB) GB for $vmName."

        # Set Network Adapter
        $networkAdapter = Get-NetworkAdapter -VM $vm | Where-Object { $_.NetworkName -ne $envSettings.NetworkName }
        if ($networkAdapter) {
            Set-NetworkAdapter -VM $vm -NetworkName $envSettings.NetworkName -AdapterType $networkAdapter.AdapterType -Confirm:$false
            Write-Host "Network adapter for $vmName set to $($envSettings.NetworkName)."
        }

        # Power on the VM
        Start-VM -VM $vm
        Write-Host "VM $vmName powered on with customized settings for $environmentType."

    } else {
        Write-Host "VM $vmName not found."
    }

    # Disconnect from vCenter
    Disconnect-VIServer -Server $vcServer -Confirm:$false
} else {
    Write-Host "Environment type $environmentType is not valid. Choose from: development, staging, production."
}
