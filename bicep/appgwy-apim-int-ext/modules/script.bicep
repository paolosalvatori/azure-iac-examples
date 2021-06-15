param location string
param timeStamp string = utcNow()
param keyVaultName string
param userAssignedIdentity string
param apiCertBase64 string
param portalCertBase64 string

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'deploymentScriptResource'
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentity}': {}
    }
  }
  location: location
  properties: {
    azPowerShellVersion: '5.0'
    cleanupPreference: 'OnSuccess'
    environmentVariables: [
      {
        name: 'keyVaultName'
        value: keyVaultName
      }
      {
        name: 'apiCert'
        secureValue: apiCertBase64
      }
      {
        name: 'portalCert'
        secureValue: portalCertBase64
      }
    ]
    forceUpdateTag: timeStamp
    timeout: 'PT1H'
    retentionInterval: 'P1D'
    scriptContent: '$apiSecret = ConvertTo-SecureString -String $env:apiCert -AsPlainText –Force;$portalSecret = ConvertTo-SecureString -String $env:portalCert -AsPlainText –Force;Set-AzKeyVaultSecret -VaultName $env:keyVaultName -Name "apicert" -SecretValue $apiSecret -ContentType "application/x-pkcs12";Set-AzKeyVaultSecret -VaultName $env:keyVaultName -Name "portalcert" -SecretValue $portalSecret -ContentType $secretContentType'
  }
}
