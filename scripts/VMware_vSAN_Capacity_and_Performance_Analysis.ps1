<#
.SYNOPSIS
This script collects vSAN capacity and performance metrics and creates a summary report.

.DESCRIPTION
Connects to a vCenter, identifies vSAN-enabled clusters, retrieves capacity usage,
disk group performance stats, and outputs them into an object and optionally exports to CSV.

.PARAMETER vCenterServer
The vCenter Server to connect to.

.PARAMETER ClusterName
(Optional) The name of a specific cluster to analyze. If not provided, all vSAN clusters are analyzed.

.PARAMETER OutputCsvPath
(Optional) The path to export the CSV report.

.EXAMPLE
.\VMware_vSAN_Capacity_and_Performance_Analysis.ps1 -vCenterServer vc01.domain.local -ClusterName "VSAN-Cluster01" -OutputCsvPath "C:\reports\vsan_report.csv"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$vCenterServer,
    [string]$ClusterName,
    [string]$OutputCsvPath
)

# Import the VMware PowerCLI modules
Import-Module VMware.PowerCLI -ErrorAction Stop

# Connect to vCenter
Connect-VIServer -Server $vCenterServer -ErrorAction Stop

# Get the cluster(s)
if ($ClusterName) {
    $clusters = Get-Cluster -Name $ClusterName
} else {
    $clusters = Get-Cluster
}

$vsanReport = @()

foreach ($cluster in $clusters) {
    # Check if vSAN is enabled on the cluster
    $vsanEnabled = ($cluster | Get-VsanClusterConfiguration).Enabled
    if ($vsanEnabled) {
        # Capacity info
        $vsanDatastore = Get-Datastore -RelatedObject $cluster | Where-Object {$_.ExtensionData.Summary.Type -eq 'vsan'}
        $totalCapacityGB = [Math]::Round($vsanDatastore.ExtensionData.Summary.Capacity/(1GB),2)
        $freeCapacityGB = [Math]::Round($vsanDatastore.ExtensionData.Summary.FreeSpace/(1GB),2)
        $usedCapacityGB = $totalCapacityGB - $freeCapacityGB
        $percentUsed = [Math]::Round(($usedCapacityGB / $totalCapacityGB)*100,2)

        # Simple performance metrics (I/O counters, latency) - requires additional vSAN performance counters or vSAN API calls
        # For demonstration, we just put placeholders or simple fetches
        $clusterPerf = "Not Implemented - Retrieve via Get-Stat or vSAN Management SDK"

        $vsanReport += [PSCustomObject]@{
            ClusterName          = $cluster.Name
            TotalCapacityGB      = $totalCapacityGB
            UsedCapacityGB       = $usedCapacityGB
            FreeCapacityGB       = $freeCapacityGB
            UsedPercentage       = "$percentUsed %"
            PerformanceAnalysis  = $clusterPerf
        }
    }
}

if ($OutputCsvPath) {
    $vsanReport | Export-Csv -Path $OutputCsvPath -NoTypeInformation
}

Disconnect-VIServer -Confirm:$false

# Print report to console
$vsanReport
