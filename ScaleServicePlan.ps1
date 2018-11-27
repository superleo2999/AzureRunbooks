param(
[parameter(Mandatory=$true)]
[string] $resourceGroupName,

[parameter(Mandatory=$true)]
[string] $appServicePlan,

[parameter(Mandatory=$false)]
[string] $defaultTier = "S1"
)

$ConnectionAssetName = "AzureClassicRunAsConnection"
$connectionName = "AzureRunAsConnection"

Write-Output "Connexion au service :"
# Get the connection
$connection = Get-AutomationConnection -Name $connectionAssetName        

# Authenticate to Azure with certificate
Write-Output "Get connection asset: $ConnectionAssetName" -Verbose
$Conn = Get-AutomationConnection -Name $ConnectionAssetName
if ($Conn -eq $null)
{ 
    throw "Could not retrieve connection asset: $ConnectionAssetName. Assure that this asset exists in the Automation account."
}

$CertificateAssetName = $Conn.CertificateAssetName
Write-Output "Getting the certificate: $CertificateAssetName" -Verbose
$AzureCert = Get-AutomationCertificate -Name $CertificateAssetName
if ($AzureCert -eq $null)
{
    throw "Could not retrieve certificate asset: $CertificateAssetName. Assure that this asset exists in the Automation account."
}

Write-Output "Authenticating to Azure with certificate." -Verbose
Set-AzureSubscription -SubscriptionName $Conn.SubscriptionName -SubscriptionId $Conn.SubscriptionID -Certificate $AzureCert 
Select-AzureSubscription -SubscriptionId $Conn.SubscriptionID


Write-Output "Connection au service RM :"
# Get the connection

try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

    "Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

#$credentialRm = Get-Credential -ServicePrincipal
Set-AzureRmAppServicePlan -Name $appServicePlan -ResourceGroupName $resourceGroupName -Tier $defaultTier -WorkerSize $defaultWorkerSize

Write-Output "Script finished."    


Write-Output "Processus de recupération terminé."