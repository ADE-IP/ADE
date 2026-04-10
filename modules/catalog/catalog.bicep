param devcentername string
param environmentName string
//param projectTeamName string = '' //required for project
param catalogName string
param catalogRepoUri string
//param adeProjectUser string = '' //required for project
param secretUri string
param catalogTasksName string
param catalogTasksRepoUri string

@secure()
@description('A PAT token is required, even for public repos')
param catalogRepoPat string
resource dc 'Microsoft.DevCenter/devcenters@2023-04-01' existing = {
  name: devcentername
}
//required for project
//resource project 'Microsoft.DevCenter/projects@2022-11-11-preview' existing = {
 //name: projectTeamName
//}
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
      secretIdentifier: !empty(catalogRepoPat) ? secretUri : null
      path: '/environment'
    }
  }
}

resource catalogTasks 'Microsoft.DevCenter/devcenters/catalogs@2022-11-11-preview' = {
  name: catalogTasksName
  parent: dc
  properties: {
    gitHub: {
      uri: catalogTasksRepoUri
      branch: 'main'
      secretIdentifier: !empty(catalogRepoPat) ? secretUri : null
      path: 'Tasks'
    }
  }
}

param environmentTypes array = ['Dev', 'Test', 'Staging']
resource envs 'Microsoft.DevCenter/devcenters/environmentTypes@2022-11-11-preview' = [for envType in environmentTypes :{
  name: envType
  parent: dc
}]

//required for project creation
//param deploymentTargetId string = subscription().id
// //var rbacRoleId = {
//   owner: '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
//   contributor: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
//   deployenvuser: '18e40d4e-8d2e-438d-97e1-9528336e149c'
// }
// output dti string = deploymentTargetId
// resource projectAssign 'Microsoft.DevCenter/projects/environmentTypes@2022-11-11-preview' =  [for envType in environmentTypes : {
//   name: envType
//   parent: project
//   identity: {
//     type: type
//   }
//   properties: {
//     creatorRoleAssignment: {
//       roles : {
//         '${rbacRoleId.contributor}': {}
//       }
//     }
//     status: 'Enabled'
//     deploymentTargetId: deploymentTargetId
//   }
// }]
