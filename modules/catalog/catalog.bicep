param devcentername string
param environmentName string
param catalogName string
param catalogRepoUri string
param secretUri string

resource dc 'Microsoft.DevCenter/devcenters@2023-04-01' existing = {
  name: devcentername
}

resource env 'Microsoft.DevCenter/devcenters/environmentTypes@2022-11-11-preview' = {
  name: environmentName
  parent: dc
}

resource catalog 'Microsoft.DevCenter/devcenters/catalogs@2022-11-11-preview' = {
  name: catalogName
  parent: dc
  properties: {
    gitHub: {
      uri: catalogRepoUri
      branch: 'main'
      secretIdentifier: secretUri
      path: '/environment'
    }
  }
}
