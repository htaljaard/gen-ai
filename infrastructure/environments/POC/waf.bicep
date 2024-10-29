//provisions a public IP address and AG running WAF V2
//https://learn.microsoft.com/en-us/azure/web-application-firewall/ag/quick-create-bicep?tabs=CLI
param vnetName string

param tags object = {}

param location string = resourceGroup().location

param resourceName string = 'anabelle'

param agName string = 'ag-${resourceName}'

resource publicIP 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: 'pip-${resourceName}'
  location: location
  tags: tags
  sku: { name: 'Standard' }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    idleTimeoutInMinutes: 4
  }
}

resource wafPolicy 'Microsoft.Network/applicationGatewayWebApplicationFirewallPolicies@2023-11-01' = {
  name: 'appGatewayWafPolicy'
  location: location
  properties: {
    policySettings: {
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
      fileUploadLimitInMb: 100
      state: 'Enabled'
      mode: 'Prevention'
    }
    customRules: []
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'OWASP'
          ruleSetVersion: '3.1'
        }
      ]
    }
  }
}

resource appGateway 'Microsoft.Network/applicationGateways@2023-11-01' = {
  name: agName
  location: location
  tags: tags
  properties: {
    sku: { capacity: 2, name: 'WAF_v2', tier: 'WAF_v2' }
    gatewayIPConfigurations: [
      {
        name: 'gatewayIpConfig'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, 'ag-subnet')
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'frontendIpConfig'
        properties: {
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'backendAddressPool'
        properties: {}
      }
    ]
    httpListeners: [
      {
        name: 'httpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', agName, 'frontendIpConfig')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', agName, 'port_80')
          }
          protocol: 'Http'
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'appGatewayBackendHttpSettings'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          requestTimeout: 20
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'requestRoutingRule'
        properties: {
          ruleType: 'Basic'
          priority: 10
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', agName, 'httpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', agName, 'backendAddressPool')
          }
          backendHttpSettings: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/backendHttpSettingsCollection',
              agName,
              'appGatewayBackendHttpSettings'
            )
          }
        }
      }
    ]
    enableHttp2: false
    firewallPolicy: { id: wafPolicy.id }
  }
}
