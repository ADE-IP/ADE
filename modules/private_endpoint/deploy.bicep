param privateEndpointName string
param location string
param privateLinkServiceId string
param subnetId string

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    customNetworkInterfaceName: '${privateEndpointName}-nic'
    privateLinkServiceConnections: []
    manualPrivateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: privateLinkServiceId
        }
      }
    ]
  }
}

// //resource privateEndpointNIC 'Microsoft.Network/networkInterfaces@2020-07-01' = {
//   name: '${privateEndpointName}-nic'
//   location: location
//   properties: {
//     ipConfigurations: [
//       {
//         name: 'ipconfig1'
//         properties: {
//           privateIPAllocationMethod: 'Dynamic'
//           subnet: {
//             id: subnetId
//           }
//         }
//       }
//     ]
//   }
// }
// resource privateDnsZone 'Microsoft.Network/privateDnsZones@2018-09-01' existing = {
//   name: nameprivateDnsZone
// }
// resource privateDnsRecord  'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
//   name: privateDnsRecordName
//   properties: {
//     ttl: 3600
//     aRecords: [
//       {
//         ipv4Address: privateEndpointNIC.properties.ipConfigurations[0].properties.privateIPAddress
//       }
//     ]
//   }
//   parent: privateDnsZone
// }
