targetScope = 'subscription'
param name string
param tags object
param location string

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: name
  location: location
  tags: tags
}

output name string = resourceGroup.name

output id string = resourceGroup.id
