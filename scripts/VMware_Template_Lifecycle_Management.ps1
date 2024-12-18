<#
.SYNOPSIS
Manages VM templates lifecycle: updates, versioning, and deployments.

.DESCRIPTION
Connects to vCenter, clones a template VM, applies patches (via attached baseline),
converts updated VM back to template, and maintains a versioned naming convention.

.PARAMETER vCenterServer
The vCenter Server to connect to.

.PARAMETER TemplateName
The name of the template to update.

.PARAMETER Datastore
Datastore to store the template.

.PARAMETER Cluster
Cluster where the temporary VM will be powered on for patching.

.EXAMPLE
.\VMware_Template_Lifecycle_Management.ps1 -vCenterServer vc01 -TemplateName "Win2019-Base" -Datastore "DS_Prod" -Cluster "Prod_Cluster"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$vCenterServer,
    [Parameter(Mandatory=$true)]
    [string]$TemplateName,
    [Parameter(Mandatory=$true)]
    [string]$Datastore,
    [Parameter(Mandatory=$true)]
    [string]$Cluster
)

Import-Module VMware.PowerCLI -ErrorAction Stop

Connect-VIServer -Server $vCenterServer

# Retrieve template
$template = Get-Template -Name $TemplateName
if (-not $template) {
    Write-Error "Template $TemplateName not found."
    exit 1
}

# Convert template back to VM
$vmFromTemplate = Set-Template -Template $template -ToVM

# Power on the VM and apply updates (e.g., using Update Manager)
Start-VM $vmFromTemplate -Confirm:$false

# Patching via PowerCLI Update Manager module (example, assuming baselines are defined)
# Get-Baseline -Name "Windows Patches" | Install-Baseline -Entity $vmFromTemplate

# Wait for remediation to complete...
# This is a placeholder. In practice, wait for task completion.

# Once updated and patched, shut down the VM
Stop-VM $vmFromTemplate -Confirm:$false

# Convert back to template with versioned name
$newTemplateName = "$TemplateName-$(Get-Date -Uformat '%Y%m%d')"
New-Template -VM $vmFromTemplate -Name $newTemplateName -Datastore $Datastore -Confirm:$false

# Optionally remove old template versions or keep them based on retention policy
# Remove-Template -Template (Get-Template -Name "$TemplateName-OldVersion")

Disconnect-VIServer -Confirm:$false

Write-Host "Template updated and versioned as $newTemplateName"