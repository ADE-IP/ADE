// Assigns the DevCenter identity permission to read secrets from Key Vault

param keyVaultName string
param principalId string

// Existing Key Vault
resource kv 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = {
  name: keyVaultName
}

// Built-in role: Key Vault Secrets User
var keyVaultSecretsUserRole = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '4633458b-17de-408a-b874-0445c86b69e6'
)

// Role Assignment to DevCenter SystemAssigned Identity
resource rbacSecretUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(kv.id, principalId, keyVaultSecretsUserRole)
  scope: kv
  properties: {
    roleDefinitionId: keyVaultSecretsUserRole
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
