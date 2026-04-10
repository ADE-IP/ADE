param privateDnsZoneName string
param DNSlocation string
param vnetid string
param privateDnsRecordName string
param privateEndpointName string
param registrationEnabled bool = false

resource privatednszones  'Microsoft.Network/privateDnsZones@2020-06-01'  = {
  name: privateDnsZoneName
  location: DNSlocation
}

resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${privateDnsZoneName}-link'
  parent: privatednszones
  location: DNSlocation
  properties: {
    registrationEnabled: registrationEnabled
    virtualNetwork: {
      id: vnetid
    }
  }
}
resource privateEndpointNIC 'Microsoft.Network/networkInterfaces@2020-07-01' existing = {
  name: '${privateEndpointName}-nic'
}

resource privateDnsRecord  'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: privateDnsRecordName
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: privateEndpointNIC.properties.ipConfigurations[0].properties.privateIPAddress
      }
    ]
  }
  parent: privatednszones
}



