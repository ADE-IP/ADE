targetScope = 'subscription'

param location string 
param devcentername string
param catalogName string
param catalogRepoUri string
param environmentName string
param tags object
param rgname string
param akvName string
param law string
param vnetname string
param addressPrefix string

@secure()
@description('A PAT token is required, even for public repos')
param catalogRepoPat string

@description('The preferred CIDR for the subnet. Default: 24')
param parSubnetCidr int = 24

// -------------------- RG --------------------
module rg '../modules/resource-group/deploy.bicep' = {
  name: 'rg-deployment'
  params: {
    name: rgname
    tags: tags
    location: location
  }
}

// -------------------- VNET --------------------
module vnet '../modules/vnet/deploy.bicep' = {
  scope: resourceGroup(rgname)
  name: '${vnetname}-vnet-deployment'
  params: {
    vnetName: vnetname
    addressPrefix: addressPrefix
    tags: tags
    location: location
    subnets: [
      {
        addressPrefix: cidrSubnet(addressPrefix, parSubnetCidr, 0)
        name: '${vnetname}-subnet'
      }
      {
        addressPrefix: cidrSubnet(addressPrefix, parSubnetCidr, 1)
        name: '${vnetname}-PEsubnet'
      }
    ]
  }
  dependsOn: [
    rg
  ]
}

// -------------------- KEY VAULT --------------------
module kv '../modules/keyvault/keyvault.bicep' = {
  scope: resourceGroup(rgname)
  name: '${deployment().name}-keyvault'
  params: {
    akvName: akvName
    location: location
  }
}

// -------------------- STORE PAT IN KV --------------------
module kvSecret '../modules/keyvault/keyvaultsecret.bicep' = if (!empty(catalogRepoPat)) {
  scope: resourceGroup(rgname)
  name: '${deployment().name}-keyvault-patSecret'
  params: {
    keyVaultName: kv.outputs.keyVaultName
    secretName: 'catalog-pat'   // ✅ fixed (no dynamic confusion)
    secretValue: catalogRepoPat
  }
}

// -------------------- DEV CENTER --------------------
module dc '../modules/devCenter/devCenter.bicep' = {
  scope: resourceGroup(rgname)
  name: devcentername
  params: {
    devcentername: devcentername
    location: location
    law: law
  }
}

// -------------------- RBAC --------------------
module rbac '../modules/keyvault/rbac.bicep' = {
  scope: resourceGroup(rgname)
  name: '${deployment().name}-managedId-rbac'
  params: {
    keyVaultName: kv.outputs.keyVaultName
    principalId: dc.outputs.dcPrincipalId
  }
  dependsOn: [
    dc
  ]
}

// -------------------- CATALOG --------------------
module ade '../modules/catalog/catalog.bicep' = {
  scope: resourceGroup(rgname)
  name: '${deployment().name}-ade'
  params: {
    devcentername: dc.name
    catalogName: catalogName
    catalogRepoUri: catalogRepoUri
    environmentName: environmentName

    // ✅ FIXED (no BCP318 issue)
    secretUri: !empty(catalogRepoPat) ? kvSecret.outputs.secretUri : ''
  }
}
