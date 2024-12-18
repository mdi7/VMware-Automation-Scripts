# PowerShell script for VMware PowerCLI Health Dashboard with Visual Interface
# Prerequisites: VMware PowerCLI and Windows Forms

# Load required assemblies for Windows Forms
Add-Type -AssemblyName "System.Windows.Forms"
Add-Type -AssemblyName "System.Drawing"

# Connect to vCenter server
$vcServer = "vcenter.example.com"
$vcUsername = "administrator@vsphere.local"
$vcPassword = "password"

# Connect to vCenter server
Connect-VIServer -Server $vcServer -User $vcUsername -Password $vcPassword

# Create a new form for the dashboard
$form = New-Object System.Windows.Forms.Form
$form.Text = "VMware PowerCLI Health Dashboard"
$form.Size = New-Object System.Drawing.Size(800, 600)

# Create labels to display metrics
$labelCpuUsage = New-Object System.Windows.Forms.Label
$labelCpuUsage.Text = "CPU Usage: N/A"
$labelCpuUsage.Location = New-Object System.Drawing.Point(20, 20)
$labelCpuUsage.Size = New-Object System.Drawing.Size(300, 20)

$labelMemoryUsage = New-Object System.Windows.Forms.Label
$labelMemoryUsage.Text = "Memory Usage: N/A"
$labelMemoryUsage.Location = New-Object System.Drawing.Point(20, 60)
$labelMemoryUsage.Size = New-Object System.Drawing.Size(300, 20)

$labelVmStatus = New-Object System.Windows.Forms.Label
$labelVmStatus.Text = "VM Status: N/A"
$labelVmStatus.Location = New-Object System.Drawing.Point(20, 100)
$labelVmStatus.Size = New-Object System.Drawing.Size(300, 20)

$labelClusterHealth = New-Object System.Windows.Forms.Label
$labelClusterHealth.Text = "Cluster Health: N/A"
$labelClusterHealth.Location = New-Object System.Drawing.Point(20, 140)
$labelClusterHealth.Size = New-Object System.Drawing.Size(300, 20)

# Create a button to refresh data
$refreshButton = New-Object System.Windows.Forms.Button
$refreshButton.Text = "Refresh Data"
$refreshButton.Location = New-Object System.Drawing.Point(20, 200)
$refreshButton.Size = New-Object System.Drawing.Size(100, 30)

# Add event handler to the button
$refreshButton.Add_Click({
    # Fetch live metrics from VMware environment
    $vms = Get-VM
    $cpuUsage = ($vms | Measure-Object -Property CPUUsage -Sum).Sum / $vms.Count
    $memoryUsage = ($vms | Measure-Object -Property MemoryUsage -Sum).Sum / $vms.Count
    $cluster = Get-Cluster | Select-Object -First 1  # Assuming we check the first cluster

    # Update labels with the live data
    $labelCpuUsage.Text = "CPU Usage: $([math]::round($cpuUsage, 2))%"
    $labelMemoryUsage.Text = "Memory Usage: $([math]::round($memoryUsage, 2)) MB"
    $labelVmStatus.Text = "VM Status: $($vms.Count) VMs"
    $labelClusterHealth.Text = "Cluster Health: $($cluster.Name) - $($cluster.DrsEnabled)"
})

# Add controls to the form
$form.Controls.Add($labelCpuUsage)
$form.Controls.Add($labelMemoryUsage)
$form.Controls.Add($labelVmStatus)
$form.Controls.Add($labelClusterHealth)
$form.Controls.Add($refreshButton)

# Show the form
$form.ShowDialog()

# Disconnect from vCenter when the form is closed
$form.Add_FormClosing({
    Disconnect-VIServer -Server $vcServer -Confirm:$false
    Write-Host "Disconnected from vCenter."
})

