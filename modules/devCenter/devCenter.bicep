param location string = resourceGroup().location
param devcentername string
param law string
param uaiName string

// -----------------------------
// User Assigned Identity
// -----------------------------
resource uai 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: uaiName
  location: location
}

// -----------------------------
// Log Analytics
// -----------------------------
resource logs 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: law
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    workspaceCapping: {
      dailyQuotaGb: 1
    }
  }
}

// -----------------------------
// Dev Center with BOTH identities
// -----------------------------
resource dc 'Microsoft.DevCenter/devcenters@2022-11-11-preview' = {
  name: devcentername
  location: location
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${uai.id}': {}
    }
  }
}

// -----------------------------
// Diagnostics
// -----------------------------
resource dcDiags 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: dc.name
  scope: dc
  properties: {
    workspaceId: logs.id
    logs: [
      {
        enabled: true
        categoryGroup: 'allLogs'
      }
      {
        enabled: true
        categoryGroup: 'audit'
      }
    ]
  }
}

// -----------------------------
// Outputs
// -----------------------------
output dcPrincipalId string = dc.identity.principalId
output uaiPrincipalId string = uai.properties.principalId
output uaiId string = uai.id
output devcentername string = dc.name
output dcid string = dc.id
