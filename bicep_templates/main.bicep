@description('Nom du Virtual Network')
param vnetName string = 'vnet-dev-calicot-cc-1'

@description('Région où le VNet sera créé')
param location string = resourceGroup().location

@description('Adresse CIDR du Virtual Network')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Sous-réseaux à créer avec leurs CIDR')
param subnets array = [
  {
    name: 'subnet1'
    addressPrefix: '10.0.1.0/24'
  }
  {
    name: 'subnet2'
    addressPrefix: '10.0.2.0/24'
  }
]

resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
      }
    }]
  }
}

output vnetId string = vnet.id
output vnetAddressPrefixes array = vnet.properties.addressSpace.addressPrefixes
