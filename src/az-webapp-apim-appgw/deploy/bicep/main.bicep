@description('The Azure region for the specified resources.')
param location string = resourceGroup().location

// ---- Azure API Management parameters ----
@description('A unique name for the API Management service. The service name refers to both the service and the corresponding Azure resource. The service name is used to generate a default domain name: <name>.azure-api.net.')
param apiManagementPublisherName string

@description('The email address to which all the notifications from API Management will be sent.')
param apiManagementPublisherEmailAddress string

@description('The API Management SKU.')
@allowed([
  'Developer'
  'Premium'
])
param apiManagementSku string = 'Developer'

@description('A custom domain name to be used for the API Management service.')
param apiManagementCustomDnsName string

@description('A custom domain name for the API Management service developer portal (e.g., portal.consoto.com). ')
param apiManagementPortalCustomHostname string

@description('A custom domain name for the API Management service gateway/proxy endpoint (e.g., api.consoto.com).')
param apiManagementProxyCustomHostname string

@description('A custom domain name for the API Management service management portal (e.g., management.consoto.com).')
param apiManagementManagementCustomHostname string

@description('Used by Application Gateway, the Base64 encoded PFX certificate corresponding to the API Management custom developer portal domain name.')
@secure()
param apiManagementPortalCustomHostnameBase64EncodedPfxCertificate string

@description('Used by Application Gateway, the Base64 encoded PFX certificate corresponding to the API Management custom proxy domain name.')
@secure()
param apiManagementProxyCustomHostnameBase64EncodedPfxCertificate string

@description('Used by Application Gateway, the Base64 encoded PFX certificate corresponding to the API Management custom management domain name.')
@secure()
param apiManagementManagementCustomHostnameBase64EncodedPfxCertificate string

// ---- Application Gateway parameters ----
@description('Used by Application Gateway, the Base64 encoded CER/CRT certificate corresponding to the root certificate for Application Gateway.')
@secure()
param applicationGatewayTrustedRootBase64EncodedPfxCertificate string

@description('The base name to be appended to all provisioned resources.')
@maxLength(13)
param resourceBaseName string = uniqueString(resourceGroup().id)

@description('The name of the Azure resource group containing the Azure Private DNS Zones used for registering private endpoints.')
param dnsZoneResourceGroupName string = resourceGroup().name

@description('The IP address prefix for the virtual network.')
param virtualNetworkAddressPrefix string = '10.7.0.0/16'

@description('The IP address prefix for the virtual network subnet used for App Service integration.')
param virtualNetworkAppServiceIntegrationSubnetAddressPrefix string = '10.7.1.0/24'

@description('The IP address prefix for the virtual network subnet used for private endpoints.')
param virtualNetworkPrivateEndpointSubnetAddressPrefix string = '10.7.2.0/24'

@description('The IP address prefix for the virtual network subnet used for Application Gateway.')
param virtualNetworkApplicationGatewaySubnetAdddressPrefix string = '10.7.3.0/24'

@description('The IP address prefix for the virtual network subnet used for API Management.')
param virtualNetworkApiManagementSubnetAddressPrefix string = '10.7.4.0/24'

@description('Indicator if new Azure Private DNS Zones should be created, or using existing Azure Private DNS Zones.')
@allowed([
  'new'
  'existing'
])
param newOrExistingDnsZones string = 'new'

// Ensure that a user-provided value is lowercase.
var baseName = empty(resourceBaseName) ? toLower(uniqueString(resourceGroup().id)) : toLower(resourceBaseName)

// ---- Variables ----
var apimUserAssignedManagedIdentityName = 'id-${baseName}-apim'
var appgwUserAssignedManagedIdentityName = 'id-${baseName}-appgw'
var keyVaultName = 'kv-${baseName}'
var applicationGatewayName = 'agw-${baseName}'
var apiManagementServiceName = 'apim-${baseName}'
var appGatewayPublicIpAddressName = 'pip-${baseName}-agw'
var vnetName = 'vnet-${baseName}'
var subnetApiManagementName = 'snet-${baseName}-apim'
var subnetAppGatewayName = 'snet-${baseName}-agw'
var subnetPrivateEndpointName = 'snet-${baseName}-pe'
var subnetAppServiceIntName = 'snet-${baseName}-ase'

var nsgAppGatewayName = 'nsg-${baseName}-agw'
var nsgApiManagementName = 'nsg-${baseName}-apim'

var webAppName = 'app-${baseName}'
var nsgName = 'nsg-${resourceBaseName}'

// ---- Create Network Security Groups (NSGs) ----
resource nsgAppGateway 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: nsgAppGatewayName
  location: location
  properties: {
    securityRules: [
      {
        name: 'agw-in'
        properties: {
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          description: 'App Gateway inbound'
          priority: 100
          sourceAddressPrefix: 'GatewayManager'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '65200-65535'
        }
      }
      {
        name: 'https-in'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
          description: 'Allow HTTPS Inbound'
        }
      }
    ]
  }
}

resource nsgApiManagemnt 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: nsgApiManagementName
  location: location
  properties: {
    securityRules: [
      {
        name: 'apim-in'
        properties: {
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          description: 'API Management inbound'
          priority: 100
          sourceAddressPrefix: 'ApiManagement'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRange: '3443'
        }
      }
    ]
  }
}

resource privateEndpointNsg 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: '${nsgName}-pe'
  location: location
}

resource appServiceIntegrationNsg 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: '${nsgName}-appServiceInt'
  location: location
}

// ---- Set up the Virtual Network ----
// NOTE: This recipe intentially does not use the ./src/common/infrastructure/bicep/network.bicep module
//       because this recipe requires two subnets that are not in the network.bicep module.
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetAppServiceIntName
        properties: {
          addressPrefix: virtualNetworkAppServiceIntegrationSubnetAddressPrefix
          networkSecurityGroup: {
            id: appServiceIntegrationNsg.id
          }
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
      {
        name: subnetPrivateEndpointName
        properties: {
          addressPrefix: virtualNetworkPrivateEndpointSubnetAddressPrefix
          networkSecurityGroup: {
            id: privateEndpointNsg.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: subnetApiManagementName
        properties: {
          addressPrefix: virtualNetworkApiManagementSubnetAddressPrefix
          networkSecurityGroup: {
            id: nsgApiManagemnt.id
          }
        }
      }
      {
        name: subnetAppGatewayName
        properties: {
          addressPrefix: virtualNetworkApplicationGatewaySubnetAdddressPrefix
          networkSecurityGroup: {
            id: nsgAppGateway.id
          }
        }
      }
    ]
  }

  resource appServiceIntegrationSubnet 'subnets' existing = {
    name: subnetAppServiceIntName
  }

  resource privateEndpointSubnet 'subnets' existing = {
    name: subnetPrivateEndpointName
  }

  resource apiMgmtSubnet 'subnets' existing = {
    name: subnetApiManagementName
  }

  resource appGatewaySubnet 'subnets' existing = {
    name: subnetAppGatewayName
  }
}

// ---- Public IP Address ----
resource applicationGatewayPublicIpAddress 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: appGatewayPublicIpAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    idleTimeoutInMinutes: 4
    ipTags: []
  }
}

// ---- Private DNS Zone ----
resource apiManagenetPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: apiManagementCustomDnsName
  location: 'global'

  resource apiRecord 'A' = {
    name: 'api'
    properties: {
      ttl: 3600
      aRecords: [
        {
          ipv4Address: apiManagementInstance.properties.privateIPAddresses[0]
        }
      ]
    }
  }

  resource managementRecord 'A' = {
    name: 'management'
    properties: {
      ttl: 3600
      aRecords: [
        {
          ipv4Address: apiManagementInstance.properties.privateIPAddresses[0]
        }
      ]
    }
  }

  resource portalRecord 'A' = {
    name: 'portal'
    properties: {
      ttl: 3600
      aRecords: [
        {
          ipv4Address: apiManagementInstance.properties.privateIPAddresses[0]
        }
      ]
    }
  }

  resource link 'virtualNetworkLinks' = {
    name: 'privateDnsZoneLink'
    location: 'global'
    properties: {
      registrationEnabled: false
      virtualNetwork: {
        id: virtualNetwork.id
      }
    }
  }
}

resource existingWebAppPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = if (newOrExistingDnsZones == 'existing') {
  name: 'privatelink.azurewebsites.net'
  scope: resourceGroup(dnsZoneResourceGroupName)
}

resource newWebAppPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (newOrExistingDnsZones == 'new') {
  name: 'privatelink.azurewebsites.net'
  location: 'Global'
}

module webAppPrivateDnsZoneLink '../../../common/infrastructure/bicep/dns-zone-vnet-mapping.bicep' = {
  name: 'privatelink-webapp-vnet-link'
  scope: resourceGroup(dnsZoneResourceGroupName)
  params: {
    privateDnsZoneName: newOrExistingDnsZones == 'new' ? newWebAppPrivateDnsZone.name : existingWebAppPrivateDnsZone.name
    vnetId: virtualNetwork.id
    vnetLinkName: '${resourceGroup().name}-link'
  }
}

// ---- Azure Web App Private Endpoint ----
resource webAppPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: 'pe-${baseName}-sites'
  location: location
  properties: {
    subnet: {
      id: virtualNetwork::privateEndpointSubnet.id
    }
    privateLinkServiceConnections: [
      {
        name: 'plsc-${baseName}-sites'
        properties: {
          privateLinkServiceId: webApp.outputs.webAppId
          groupIds: [
            'sites'
          ]
        }
      }
    ]
  }

  resource webAppPrivateDnsZoneGroup 'privateDnsZoneGroups' = {
    name: 'webAppPrivateDnsZoneGroup'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: 'config'
          properties: {
            privateDnsZoneId: newOrExistingDnsZones == 'new' ? newWebAppPrivateDnsZone.id : existingWebAppPrivateDnsZone.id //existingWebAppPrivateDnsZone.id
          }
        }
      ]
    }
  }
}

// ---- Application Insights ----
module applicationInsights '../../../common/infrastructure/bicep/app-insights.bicep' = {
  name: 'appInsightsDeploy'
  params: {
    location: location
    resourceBaseName: baseName
  }
}

// ---- Azure Web App ----
module webApp '../../../common/infrastructure/bicep/web-app.bicep' = {
  name: 'webAppDeploy'
  params: {
    location: location
    webAppName: webAppName
    resourceBaseName: baseName
    virtualNetworkSubnetId: virtualNetwork::appServiceIntegrationSubnet.id
    vnetRouteAllEnabled: true
  }
}

resource webAppSettings 'Microsoft.Web/sites/config@2021-01-15' = {
  dependsOn: [
    webApp
  ]
  name: '${webAppName}/appsettings'
  properties: {
    APPINSIGHTS_INSTRUMENTATIONKEY: '@Microsoft.KeyVault(SecretUri=${appInsightsInstrumentationKeyKeyVaultSecret.properties.secretUri})'
  }
}

// ---- Azure API Management and related API operations ----

resource apimUserAssignedManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: apimUserAssignedManagedIdentityName
  location: location
}

resource apiManagementInstance 'Microsoft.ApiManagement/service@2021-01-01-preview' = {
  name: apiManagementServiceName
  dependsOn: []
  location: location
  sku: {
    capacity: 1
    name: apiManagementSku
  }
  // NOTE: Bicep does not have a separate resource for API Management custom domains.
  //       The certificates used in the API Management hostnameConfigurations property must then exist as Key Vault secrets and be accessible by the API Management service before the service is created.
  //       In order to give secret access to the API Management service, a Key Vault access policy is required that references the pre-created API Management service.
  //       A circular dependency results - To create the API Management service, the Key Vault access policy for APIM must exist. To create the Key Vault access policy for APIM, however, the API Management service must exist.
  //       To break the circular dependency, a User Assigned Managed Identity is used as it can be created before the API Management instance and given secret 'get' access on the Key Vault.
  //       The User Assigned Managed Identity can then be attached to the API Management service and used to retrieve the Key Vault secret at the time the service is created.
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${apimUserAssignedManagedIdentity.id}': {}
    }
  }
  properties: {
    publisherEmail: apiManagementPublisherEmailAddress
    publisherName: apiManagementPublisherName
    virtualNetworkType: 'Internal'
    virtualNetworkConfiguration: {
      subnetResourceId: virtualNetwork::apiMgmtSubnet.id
    }
    hostnameConfigurations: [
      {
        type: 'DeveloperPortal'
        hostName: apiManagementPortalCustomHostname
        keyVaultId: portalCustomDomainCertificateKeyVaultSecret.properties.secretUri
        identityClientId: apimUserAssignedManagedIdentity.properties.clientId
        defaultSslBinding: false
      }
      {
        type: 'Proxy'
        hostName: apiManagementProxyCustomHostname
        keyVaultId: gatewayCustomDomainCertificateKeyVaultSecret.properties.secretUri
        identityClientId: apimUserAssignedManagedIdentity.properties.clientId
        defaultSslBinding: true
      }
      {
        type: 'Management'
        hostName: apiManagementManagementCustomHostname
        keyVaultId: managementCustomDomainCertificateKeyVaultSecret.properties.secretUri
        identityClientId: apimUserAssignedManagedIdentity.properties.clientId
        defaultSslBinding: false
      }
    ]
  }

  resource weatherApi 'apis' = {
    name: 'weatherForecastApi'
    properties: {
      path: ''
      protocols: [
        'https'
      ]
      displayName: 'WeatherForecast'
      serviceUrl: 'https://${webApp.outputs.defaultHostname}'
    }

    resource weatherApiOperationGET 'operations' = {
      name: 'GetForecast'
      properties: {
        method: 'GET'
        displayName: 'GetForecast'
        description: 'Retrieves weather forecast.'
        urlTemplate: '/weatherforecast'
        responses: [
          {
            statusCode: 200
          }
        ]
      }
    }
  }

  resource appInsightsLogger 'loggers' = {
    name: 'appInsightsLogger'
    properties: {
      loggerType: 'applicationInsights'
      credentials: {
        instrumentationKey: applicationInsights.outputs.instrumentationKey
      }
    }
  }

  resource appInsightsDiagnostics 'diagnostics' = {
    name: 'applicationinsights'
    properties: {
      loggerId: appInsightsLogger.id
      logClientIp: true
      alwaysLog: 'allErrors'
      verbosity: 'information'
      sampling: {
        percentage: 100
        samplingType: 'fixed'
      }
      httpCorrelationProtocol: 'Legacy'
    }
  }
}

resource apiManagementDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: apiManagementInstance
  name: 'apiManagementDiagnosticSettings'
  properties: {
    workspaceId: applicationInsights.outputs.workspaceId
    logs: [
      {
        category: 'GatewayLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// ---- Azure Application Gateway ----

resource appgwUserAssignedManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: appgwUserAssignedManagedIdentityName
  location: location
}

resource applicationGateway 'Microsoft.Network/applicationGateways@2020-11-01' = {
  name: applicationGatewayName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${appgwUserAssignedManagedIdentity.id}': {}
    }
  }
  dependsOn: [
    apiManagenetPrivateDnsZone
    apiManagementInstance
  ]
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
      capacity: 2
    }
    gatewayIPConfigurations: [
      {
        name: 'gatewayIP01'
        properties: {
          subnet: {
            id: virtualNetwork::appGatewaySubnet.id
          }
        }
      }
    ]
    sslCertificates: [
      {
        name: 'gatewaycert'
        properties: {
          keyVaultSecretId: gatewayCustomDomainCertificateKeyVaultSecret.properties.secretUri
        }
      }
      {
        name: 'portalcert'
        properties: {
          keyVaultSecretId: portalCustomDomainCertificateKeyVaultSecret.properties.secretUri
        }
      }
      {
        name: 'managementcert'
        properties: {
          keyVaultSecretId: managementCustomDomainCertificateKeyVaultSecret.properties.secretUri
        }
      }
    ]
    trustedRootCertificates: [
      {
        name: 'trustedrootcert'
        properties: {
          data: applicationGatewayTrustedRootBase64EncodedPfxCertificate
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'frontend1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: applicationGatewayPublicIpAddress.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port01'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'gatewaybackend'
        properties: {
          backendAddresses: [
            {
              fqdn: apiManagementProxyCustomHostname
            }
          ]
        }
      }
      {
        name: 'portalbackend'
        properties: {
          backendAddresses: [
            {
              fqdn: apiManagementPortalCustomHostname
            }
          ]
        }
      }
      {
        name: 'managementbackend'
        properties: {
          backendAddresses: [
            {
              fqdn: apiManagementManagementCustomHostname
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'apimPoolGatewaySetting'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          requestTimeout: 180
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', applicationGatewayName, 'apimgatewayprobe')
          }
          trustedRootCertificates: [
            {
              id: resourceId('Microsoft.Network/applicationGateways/trustedRootCertificates', applicationGatewayName, 'trustedrootcert')
            }
          ]
        }
      }
      {
        name: 'apimPoolPortalSetting'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          requestTimeout: 180
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', applicationGatewayName, 'apimportalprobe')
          }
          trustedRootCertificates: [
            {
              id: resourceId('Microsoft.Network/applicationGateways/trustedRootCertificates', applicationGatewayName, 'trustedrootcert')
            }
          ]
        }
      }
      {
        name: 'apimPoolManagementSetting'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          requestTimeout: 180
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', applicationGatewayName, 'apimmanagementprobe')
          }
          trustedRootCertificates: [
            {
              id: resourceId('Microsoft.Network/applicationGateways/trustedRootCertificates', applicationGatewayName, 'trustedrootcert')
            }
          ]
        }
      }
    ]
    httpListeners: [
      {
        name: 'gatewaylistener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName, 'frontend1')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName, 'port01')
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', applicationGatewayName, 'gatewaycert')
          }
          hostName: apiManagementProxyCustomHostname
          requireServerNameIndication: true
          hostNames: []
          customErrorConfigurations: []
        }
      }
      {
        name: 'portallistener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName, 'frontend1')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName, 'port01')
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', applicationGatewayName, 'portalcert')
          }
          hostName: apiManagementPortalCustomHostname
          requireServerNameIndication: true
          hostNames: []
          customErrorConfigurations: []
        }
      }
      {
        name: 'managementlistener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName, 'frontend1')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName, 'port01')
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', applicationGatewayName, 'managementcert')
          }
          hostName: apiManagementManagementCustomHostname
          requireServerNameIndication: true
          hostNames: []
          customErrorConfigurations: []
        }
      }
    ]
    urlPathMaps: []
    requestRoutingRules: [
      {
        name: 'gatewayrule'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, 'gatewaylistener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName, 'gatewaybackend')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGatewayName, 'apimPoolGatewaySetting')
          }
        }
      }
      {
        name: 'portalrule'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, 'portallistener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName, 'portalbackend')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGatewayName, 'apimPoolPortalSetting')
          }
        }
      }
      {
        name: 'managementrule'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, 'managementlistener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName, 'managementbackend')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGatewayName, 'apimPoolManagementSetting')
          }
        }
      }
    ]
    probes: [
      {
        name: 'apimgatewayprobe'
        properties: {
          protocol: 'Https'
          host: apiManagementProxyCustomHostname
          path: '/status-0123456789abcdef'
          interval: 30
          timeout: 120
          unhealthyThreshold: 8
          pickHostNameFromBackendHttpSettings: false
          minServers: 0
          match: {}
        }
      }
      {
        name: 'apimportalprobe'
        properties: {
          protocol: 'Https'
          host: apiManagementPortalCustomHostname
          path: '/signin'
          interval: 60
          timeout: 300
          unhealthyThreshold: 8
          pickHostNameFromBackendHttpSettings: false
          minServers: 0
          match: {}
        }
      }
      {
        name: 'apimmanagementprobe'
        properties: {
          protocol: 'Https'
          host: apiManagementManagementCustomHostname
          path: '/ServiceStatus'
          interval: 60
          timeout: 300
          unhealthyThreshold: 8
          pickHostNameFromBackendHttpSettings: false
          minServers: 0
          match: {}
        }
      }
    ]
    sslPolicy: {
      policyType: 'Predefined'
      policyName: 'AppGwSslPolicy20170401S'
    }
    rewriteRuleSets: []
    redirectConfigurations: []
    privateLinkConfigurations: []
    webApplicationFirewallConfiguration: {
      enabled: true
      firewallMode: 'Detection'
      ruleSetType: 'OWASP'
      ruleSetVersion: '3.2'
      disabledRuleGroups: []
      exclusions: []
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
      fileUploadLimitInMb: 100
    }
  }
}

resource applicationGatewayDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: applicationGateway
  name: 'diagnosticSettings'
  properties: {
    workspaceId: applicationInsights.outputs.workspaceId
    logs: [
      {
        category: 'ApplicationGatewayAccessLog'
        enabled: true
      }
      {
        category: 'ApplicationGatewayPerformanceLog'
        enabled: true
      }
      {
        category: 'ApplicationGatewayFirewallLog'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// ---- Azure Key Vault ----
module keyVault '../../../common/infrastructure/bicep/private-key-vault.bicep' = {
  name: 'keyVaultDeploy'
  params: {
    location: location
    resourceBaseName: baseName
    virtualNetworkId: virtualNetwork.id
    subnetPrivateEndpointId: virtualNetwork::privateEndpointSubnet.id
    subnetPrivateEndpointName: subnetPrivateEndpointName
    dnsZoneResourceGroupName: dnsZoneResourceGroupName
    newOrExistingDnsZone: newOrExistingDnsZones
    keyVaultName: keyVaultName
    keyVaultTenantId: apimUserAssignedManagedIdentity.properties.tenantId
    // NOTE: User Assigned Managed Identity used in API Management isn't able to access Key Vault secrets when defaultAction is set to Deny.
    //       DefaultAction is set to Allow so API Management custom domains can reference certificates stored as Key Vault secrets.
    keyVaultNetworkAclsDefaultAction: 'Allow'
    keyVaultAccessPolicies: [
      {
        tenantId: webApp.outputs.webAppTenantId
        objectId: webApp.outputs.webAppPrincipalId
        permissions: {
          secrets: [
            'get'
          ]
        }
      }
      {
        tenantId: apimUserAssignedManagedIdentity.properties.tenantId
        objectId: apimUserAssignedManagedIdentity.properties.principalId
        permissions: {
          secrets: [
            'get'
          ]
        }
      }
      {
        tenantId: appgwUserAssignedManagedIdentity.properties.tenantId
        objectId: appgwUserAssignedManagedIdentity.properties.principalId
        permissions: {
          secrets: [
            'get'
          ]
        }
      }
    ]
  }
}

resource appInsightsInstrumentationKeyKeyVaultSecret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: '${keyVaultName}/kvs-${baseName}-aikey'
  dependsOn: [
    keyVault
  ]
  properties: {
    value: applicationInsights.outputs.instrumentationKey
  }
}

resource gatewayCustomDomainCertificateKeyVaultSecret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: '${keyVaultName}/kvs-${baseName}-gateway-certificate'
  dependsOn: [
    keyVault
  ]
  properties: {
    value: apiManagementProxyCustomHostnameBase64EncodedPfxCertificate
    contentType: 'application/x-pkcs12'
    attributes: {
      enabled: true
      nbf: 1636982768
      exp: 1779814000
    }
  }
}

resource portalCustomDomainCertificateKeyVaultSecret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: '${keyVaultName}/kvs-${baseName}-portal-certificate'
  dependsOn: [
    keyVault
  ]
  properties: {
    value: apiManagementPortalCustomHostnameBase64EncodedPfxCertificate
    contentType: 'application/x-pkcs12'
    attributes: {
      enabled: true
      nbf: 1636982768
      exp: 1779814000
    }
  }
}

resource managementCustomDomainCertificateKeyVaultSecret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: '${keyVaultName}/kvs-${baseName}-management-certificate'
  dependsOn: [
    keyVault
  ]
  properties: {
    value: apiManagementManagementCustomHostnameBase64EncodedPfxCertificate
    contentType: 'application/x-pkcs12'
    attributes: {
      enabled: true
      nbf: 1636982768
      exp: 1779814000
    }
  }
}

output webAppName string = webApp.outputs.webAppName
output webAppPlanName string = webApp.outputs.webAppPlanName
output virtualNetworkName string = virtualNetwork.name
