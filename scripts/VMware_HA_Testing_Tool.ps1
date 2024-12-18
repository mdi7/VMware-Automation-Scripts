# PowerShell script for VMware HA (High Availability) Testing Tool
# Prerequisites: VMware PowerCLI module installed

# Define vCenter connection credentials
$vcServer = "vcenter.example.com"
$vcUsername = "administrator@vsphere.local"
$vcPassword = "password"
$testReportPath = "C:\VMware_HA_Test_Report.txt"  # Path for saving the test report

# Connect to vCenter
Connect-VIServer -Server $vcServer -User $vcUsername -Password $vcPassword

# Function to simulate host failure
function Simulate-HostFailure {
    Write-Host "Simulating host failure..."

    # Get all ESXi hosts in the cluster
    $hosts = Get-VMHost

    # Select a random host to simulate failure
    $failoverHost = $hosts | Get-Random
    Write-Host "Simulating failure on host: $($failoverHost.Name)"

    # Simulate the host failure by disabling the host (this will trigger HA)
    Set-VMHost -VMHost $failoverHost -State "Maintenance" -Confirm:$false
    Write-Host "Host $($failoverHost.Name) has been marked as failed."

    # Wait for HA to trigger and migrate VMs to other hosts
    Start-Sleep -Seconds 30  # Wait for HA to trigger the VM failover

    # Check if the VMs are properly migrated
    $vmsOnFailoverHost = Get-VM | Where-Object { $_.Host.Name -eq $failoverHost.Name }
    $migratedVMs = $vmsOnFailoverHost | Where-Object { $_.PowerState -eq "PoweredOn" }

    return $migratedVMs
}

# Function to validate HA configuration and generate a test report
function Validate-HASystem {
    Write-Host "Validating HA system configuration..."

    # Fetch all VMs that are powered on
    $vms = Get-VM | Where-Object { $_.PowerState -eq "PoweredOn" }

    # Generate the report header
    $reportContent = "VMware HA Testing Report - $(Get-Date)`n"
    $reportContent += "--------------------------------------------------`n"

    # Simulate a host failure and check VM migration
    $migratedVMs = Simulate-HostFailure

    # Add results of the test to the report
    if ($migratedVMs.Count -gt 0) {
        $reportContent += "Host failure simulation successful. The following VMs were migrated successfully:`n"
        foreach ($vm in $migratedVMs) {
            $reportContent += "VM: $($vm.Name) - Migrated to Host: $($vm.Host.Name)`n"
        }
    } else {
        $reportContent += "No VMs were migrated successfully after the host failure simulation. Test failed.`n"
    }

    # Save the report to the specified path
    $reportContent | Out-File -FilePath $testReportPath -Force
    Write-Host "HA test report generated and saved to $testReportPath"
}

# Run the HA validation test
Validate-HASystem

# Disconnect from vCenter
Disconnect-VIServer -Server $vcServer -Confirm:$false

Write-Host "VMware HA Testing completed."
