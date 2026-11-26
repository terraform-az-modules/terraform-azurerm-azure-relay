<!-- BEGIN_TF_DOCS -->

# Azure Relay Basic

This example creates a resource group and an Azure Relay namespace with one hybrid connection.

## Modules

| Name | Source | Version |
|------|--------|---------|
| resource_group | terraform-az-modules/resource-group/azurerm | 1.0.4 |
| azure_relay | ../../ | n/a |

## Outputs

| Name | Description |
|------|-------------|
| `relay_namespace_name` | The Relay namespace name. |
| `hybrid_connection_ids` | Hybrid connection IDs keyed by hybrid connection name. |

<!-- END_TF_DOCS -->
