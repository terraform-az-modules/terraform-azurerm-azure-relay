<!-- BEGIN_TF_DOCS -->

# Azure Relay Complete

This example creates a resource group, VNet, subnet, Log Analytics workspace and `privatelink.servicebus.windows.net` private DNS zone, then an Azure Relay namespace with a namespace-level policy, a hybrid connection with listener and sender policies, a private endpoint and diagnostic settings.

## Modules

| Name | Source | Version |
|------|--------|---------|
| resource_group | terraform-az-modules/resource-group/azurerm | 1.0.4 |
| vnet | terraform-az-modules/vnet/azurerm | 1.0.4 |
| subnet | terraform-az-modules/subnet/azurerm | 1.0.3 |
| log-analytics | terraform-az-modules/log-analytics/azurerm | 2.1.0 |
| private_dns_zone | terraform-az-modules/private-dns/azurerm | 1.0.8 |
| azure_relay | ../.. | n/a |

## Outputs

| Name | Description |
|------|-------------|
| `relay_namespace_id` | The Relay namespace ID. |
| `relay_namespace_fqdn` | The Relay namespace FQDN. |
| `hybrid_connection_ids` | Hybrid connection IDs keyed by hybrid connection name. |
| `private_endpoint_ip_address` | The private IP address of the Relay namespace private endpoint. |
| `hybrid_connection_authorization_rules` | Hybrid connection authorization rules with keys and connection strings (sensitive). |

<!-- END_TF_DOCS -->
