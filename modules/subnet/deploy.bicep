param vnetName string
param subnetName string
param subnetPrefix string

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' = {
  name: '${vnetName}/${subnetName}'
  properties: {
    addressPrefix: subnetPrefix
  }
}

output subnetId string = subnet.id
