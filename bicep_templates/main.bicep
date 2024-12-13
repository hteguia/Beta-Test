@description('Nom du Virtual Network')
param vnetName string = 'vnet-dev-calicot-cc-1'

@description('Région où le VNet sera créé')
param location string = resourceGroup().location

@description('Adresse CIDR du Virtual Network')
param vnetAddressPrefix string = '10.0.0.0/16'

param codeIdentification string  = '1' // Paramètre pour l'identifiant unique

param connectionString string  = 'Data Source=LAPTOP-NBKHUSGP;Initial Catalog=Auctions_Data;Encrypt=False; Integrated Security=True;Pooling=False' // Paramètre pour la chaîne de connexion à la base de données

// Nom du serveur SQL
param sqlServerName string = 'sqlsrv-calicot-dev-${codeIdentification}'

// Nom de la base de données
param sqlDbName string = 'sqldb-calicot-dev-${codeIdentification}'

@description('Sous-réseaux à créer avec leurs CIDR')
param subnets array = [
  {
    name: 'snet-dev-web-cc-${codeIdentification}'
    addressPrefix: '10.0.1.0/24'
  }
  {
    name: 'snet-dev-db-cc-${codeIdentification}'
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

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: 'plan-calicot-dev-${codeIdentification}'
  location: location
  sku: {
    name: 'S1'  // Tier Standard S1
    capacity: 1  // Nombre d'instances initiales
  }
  properties: {
    perSiteScaling: false  // Permet l'auto-scaling au niveau du plan
    reserved: false  // Désactive le mode Linux, utilisé pour Windows
  }
}

resource webApp 'Microsoft.Web/sites@2022-03-01' = {
  name: 'app-calicot-dev-${codeIdentification}'
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true  // Forcer les communications via HTTPS uniquement
    siteConfig: {
      alwaysOn: true  // Prévenir la mise en veille (Always On)
    }
  }
}

// resource scalingSettings 'Microsoft.Insights/autoscalesettings@2022-10-01' = {
//   name: 'autoscale-settings-${codeIdentification}'
//   location: location
//   properties: {
//     targetResourceId: appServicePlan.id
//     enabled: true
//     profiles: [
//       {
//         name: 'default-profile'
//         capacity: {
//           minimum: '1'  // Instance de base
//           maximum: '2'  // Limite supérieure du scale-out
//           default: '1'
//         }
//         rules: [
//           {
//             metricName: 'CpuPercentage'
//             timeAggregation: 'Average'
//             operator: 'GreaterThan'
//             threshold: 70
//             direction: 'Increase'
//             changeCount: 1
//             cooldown: 'PT5M'
//             metricTrigger: ''
//             scaleAction: ''
//           }
//           {
//             metricName: 'CpuPercentage'
//             timeAggregation: 'Average'
//             operator: 'LessThan'
//             threshold: 30
//             direction: 'Decrease'
//             changeCount: 1
//             cooldown: 'PT5M'
//           }
//         ]
//       }
//     ]
//   }
// }

// Création du Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: 'kv-calicot-dev-${codeIdentification}'  // Nom de la Key Vault
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'  // SKU standard pour le Key Vault
    }
    tenantId: '764531e1-0809-47fc-a5f1-c23447738009'  // ID de votre tenant Azure (remplacez par le vôtre)
  }
}

// Création du secret dans la Key Vault
resource secret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: 'ConnectionStrings'  // Nom du secret
  properties: {
    value: connectionString  // Valeur du secret (la chaîne de connexion)
  }
}


// Déployer le serveur SQL
// resource sqlServer 'Microsoft.Sql/servers@2021-02-01-preview' = {
//   name: sqlServerName
//   location: location
//   properties: {
//     administratorLogin: 'sqladmin'  // Identifiant d'administrateur de la base de données
//     administratorLoginPassword: 'your-secure-password'  // Remplacez par un mot de passe sécurisé
//   }
// }

// // Déployer la base de données SQL
// resource sqlDatabase 'Microsoft.Sql/servers/databases@2021-02-01-preview' = {
//   parent: sqlServer
//   name: sqlDbName
//   location: location
//   properties: {
//     sku: {
//       name: 'Basic'
//       tier: 'Basic'
//       capacity: 5  // Capacité de la base de données pour le niveau Basic
//     }
//   }
// }

output vnetId string = vnet.id
output vnetAddressPrefixes array = vnet.properties.addressSpace.addressPrefixes
