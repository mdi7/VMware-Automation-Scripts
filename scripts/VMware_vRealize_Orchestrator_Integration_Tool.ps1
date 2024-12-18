<#
.SYNOPSIS
Integrate with vRealize Orchestrator to trigger workflows.

.DESCRIPTION
Connects to vRO via REST API, lists available workflows, triggers a specified workflow,
and monitors its execution state.

.PARAMETER vROServer
The vRealize Orchestrator server.

.PARAMETER WorkflowName
Name of the workflow to trigger.

.EXAMPLE
.\VMware_vRealize_Orchestrator_Integration_Tool.ps1 -vROServer vro.domain.local -WorkflowName "Provision New VM"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$vROServer,
    [Parameter(Mandatory=$true)]
    [string]$UserName,
    [Parameter(Mandatory=$true)]
    [SecureString]$Password,
    [Parameter(Mandatory=$true)]
    [string]$WorkflowName
)

$Cred = New-Object System.Management.Automation.PSCredential($UserName, $Password)
$authHeader = "Basic " + [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(($Cred.UserName + ":" + $Cred.GetNetworkCredential().Password)))
$Headers = @{
    Authorization = $authHeader
    Accept        = 'application/json'
    Content-Type  = 'application/json'
}

# Get workflow ID by name
$workflows = Invoke-RestMethod -Uri "https://$vROServer/vco/api/workflows?conditions=name=$WorkflowName" -Headers $Headers -Method GET -SkipCertificateCheck
if (-not $workflows.link) {
    Write-Error "Workflow $WorkflowName not found."
    exit 1
}

$workflowLink = $workflows.link | Where-Object {$_.attributes.name -eq $WorkflowName}
$workflowId = $workflowLink.attributes.id

Write-Host "Found Workflow: $WorkflowName with ID: $workflowId"

# Execute the workflow
$executionResult = Invoke-RestMethod -Uri "https://$vROServer/vco/api/workflows/$workflowId/executions" -Headers $Headers -Method POST -Body "{}" -SkipCertificateCheck
$executionId = $executionResult.id

Write-Host "Triggered Workflow Execution ID: $executionId"

# Poll the workflow execution state until it's completed
do {
    Start-Sleep -Seconds 5
    $currentState = Invoke-RestMethod -Uri "https://$vROServer/vco/api/workflows/$workflowId/executions/$executionId" -Headers $Headers -Method GET -SkipCertificateCheck
    Write-Host "Workflow State: $($currentState.state)"
} while ($currentState.state -inotmatch 'completed|failed|canceled')

Write-Host "Workflow completed with state: $($currentState.state)"