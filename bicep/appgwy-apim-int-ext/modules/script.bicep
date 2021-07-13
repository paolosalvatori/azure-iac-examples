param location string
param timeStamp string = utcNow()
param keyVaultName string
param userAssignedIdentity string
param certificateName string
param certificateBase64String string
param certificatePassword string

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
        name: 'certificateName'
        value: certificateName
      }
      {
        name: 'certificateBase64String'
        secureValue: certificateBase64String
      }
      {
        name: 'certificatePassword'
        secureValue: certificatePassword
      }
    ]
    forceUpdateTag: timeStamp
    timeout: 'PT1H'
    retentionInterval: 'P1D'
    scriptContent: 'Import-AzKeyVaultCertificate -VaultName $env:keyVaultName -Name $env:certificateName -Password $env:certificatePassword -CertificateString $env:certificateBase64String'
    //scriptContent: '$apiSecret = ConvertTo-SecureString -String $env:apiCert -AsPlainText –Force;$portalSecret = ConvertTo-SecureString -String $env:portalCert -AsPlainText –Force;Set-AzKeyVaultSecret -VaultName $env:keyVaultName -Name "apicert" -SecretValue $apiSecret -ContentType "application/x-pkcs12";Set-AzKeyVaultSecret -VaultName $env:keyVaultName -Name "portalcert" -SecretValue $portalSecret -ContentType $secretContentType'
  }
}
