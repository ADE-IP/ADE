param devcentername string
param subscriptionid string
param rgname string
param ComputeGalleryName string
//param ComputeGalleryName string = 'xmew1dopsstampdcomputegallery001'
param galleryResourceId string = '/subscriptions/${subscriptionid}/resourceGroups/${rgname}/providers/Microsoft.Compute/galleries/${ComputeGalleryName}'

// DevCenter Galleries
resource galleries 'Microsoft.DevCenter/devcenters/galleries@2023-04-01' = {
  parent: devcenter
  name: ComputeGalleryName
  properties: {
    galleryResourceId: galleryResourceId
  }
}

resource devcenter 'Microsoft.DevCenter/devcenters@2023-04-01' existing = {
  name: devcentername
}
