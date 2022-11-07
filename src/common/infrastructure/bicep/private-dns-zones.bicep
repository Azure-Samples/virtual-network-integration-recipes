@description('The array of the names of the Azure Private DNS Zones to be created/used.')
param privateDnsNames array

@description('The tags to be applied to the provisioned resources.')
param tags object

// Private DNS zones
resource privateDnsZones 'Microsoft.Network/privateDnsZones@2020-06-01' = [ for dnsName in privateDnsNames: {
  name: dnsName
  location: 'global'
  tags: tags
}]

output outPrivateDnsZones array = [ for (names, i) in privateDnsNames: {
  privateDnsName: privateDnsNames
  privateDnsZoneName: privateDnsZones[i].name
  privateDnsZoneId: privateDnsZones[i].id
}]
