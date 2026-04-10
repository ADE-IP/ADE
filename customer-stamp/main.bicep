targetScope = 'subscription'
param location string 
param devcentername string
//param projectTeamName string
param catalogName string
param catalogRepoUri string
param catalogTasksName string
param catalogTasksRepoUri string
param environmentName string
param tags object
param rgname string
param akvName string
param law string
param vnetname string
param addressPrefix string
param privateDnsZoneName string
param DNSlocation string = 'global'
param privateEndpointName string
param privateLinkServiceId string
param privateDnsRecordName string
param sharedrgName string
param sharedsubscriptionid string
param ComputeGalleryName string

@secure()
@description('A PAT token is required, even for public repos')
param catalogRepoPat string
@description('The preferred CIDR for the subnet. Default: 25')
param parSubnetCidr int = 24

@description('The amount of subnets to create. Default: 2')
//param parAmountOfSubnets int = 2
//var varSubnetCalculations = map(range(0, parAmountOfSubnets), i)

module rg '../modules/resource-group/deploy.bicep' = {
  name: 'rg-deployment'
  params: {
    name: rgname
    tags: tags
    location: location
  }
}

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
               //addressPrefix: '${address}.0.0/${subnetPrefix}'function range(startIndex: int, count: int): int[]
               addressPrefix:cidrSubnet(addressPrefix, parSubnetCidr, 0)
               name: '${vnetname}-subnet'
           }
           {
             //addressPrefix: '10.9.2.0/24'
             //addressPrefix: '${address}.1.0/${subnetPrefix}'
             addressPrefix:cidrSubnet(addressPrefix, parSubnetCidr, 1)
             name: '${vnetname}-PEsubnet'
         }
       ]
   }
   dependsOn: [
       rg
   ]
 }

 @description('A keyvault is required to store your pat token for the Catalog')
 module kv '../modules/keyvault/keyvault.bicep' = {
   scope: resourceGroup(rgname)
   name: '${deployment().name}-keyvault'
   params: {
     akvName: akvName
     location: location
        }
 }

 @description('Keyvault secrect holds pat token')
 module kvSecret '../modules/keyvault/keyvaultsecret.bicep' = if (!empty(catalogRepoPat)) {
   scope: resourceGroup(rgname)
   name: '${deployment().name}-keyvault-patSecret'
   params: {
     keyVaultName: kv.outputs.keyVaultName
     secretName: catalogName
     secretValue: catalogRepoPat
   }
 }

 module rbac '../modules/keyvault/rbac.bicep' = {
   scope: resourceGroup(rgname)
   name: '${deployment().name}-managedId-rbac'
   params: {
     keyVaultName: kv.outputs.keyVaultName
     sharedrgName: sharedrgName
     sharedsubscriptionid: sharedsubscriptionid
   }
   dependsOn: [
    dc
   ]
 }


module dc '../modules/devCenter/devCenter.bicep' = {
  scope: resourceGroup(rgname)
  name: devcentername
  params: {
    devcentername: devcentername
    sharedrgName: sharedrgName
    location: location
    law: law
    sharedsubscriptionid: sharedsubscriptionid
    //type: type
    //existingImageGalleryName: existingImageGalleryName
  }
}

 module dcgallery '../modules/devCenter/dcgallery.bicep' = {
   scope: resourceGroup(rgname)
   name: 'dcgallerydeploy'
   params: {
     devcentername: devcentername
     ComputeGalleryName: ComputeGalleryName
     //ComputeGalleryName: 'xmew1dopsstampdcomputegallery001'
     sharedrgName: sharedrgName
     sharedsubscriptionid: sharedsubscriptionid
   }
   dependsOn:[dc,ade]
 }

 module ade '../modules/catalog/catalog.bicep' = {
   scope: resourceGroup(rgname)
   name: '${deployment().name}-ade'
   params: {
     devcentername: dc.name
     catalogName: catalogName
     catalogRepoUri: catalogRepoUri
     catalogTasksName: catalogTasksName
     catalogTasksRepoUri: catalogTasksRepoUri
     environmentName: environmentName
     catalogRepoPat: catalogRepoPat
     secretUri: kvSecret.outputs.secretUri
     //adeProjectUser: devboxProjectUser
     
   }
 }
 module privateDnsZone '../modules/private-dns-zone/private_dns_zone.bicep' = {
  scope: resourceGroup(rgname)
  name: 'privateDnsZone'
  params: {
    privateDnsZoneName: privateDnsZoneName
    DNSlocation: DNSlocation
    vnetid: vnet.outputs.vnetId
    privateEndpointName: privateEndpointName
    privateDnsRecordName: privateDnsRecordName
  }
  dependsOn:[privateendpoint]
}
module privateendpoint '../modules/private_endpoint/deploy.bicep' = {
  scope: resourceGroup(rgname)
  name: 'privateendpoint'
  params: {
    privateEndpointName: privateEndpointName
    location: location
    privateLinkServiceId: privateLinkServiceId
    subnetId: vnet.outputs.subnetResourceIds[1]
  }
}

//  //module project '../modules/dcProject/dcProject.bicep' = {
//  scope: resourceGroup(rgname)
//  name: projectTeamName
//  params: {
//  projectTeamName: projectTeamName
//  //devboxProjectUser: devboxProjectUser
//  location: location
//  dcid: dc.outputs.dcnid
//  }
//  }        "ComputeGalleryName":{
  //"value": "$(ComputeGalleryName)"
//}

