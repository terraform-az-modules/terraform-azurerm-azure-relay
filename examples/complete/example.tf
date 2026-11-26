provider "azurerm" {
  features {}
}

locals {
  name        = "app"
  environment = "test"
  location    = "canadacentral"
  label_order = ["name", "environment", "location"]
}

##-----------------------------------------------------------------------------
## Resource Group
##-----------------------------------------------------------------------------
module "resource_group" {
  source      = "terraform-az-modules/resource-group/azurerm"
  version     = "1.0.4"
  name        = local.name
  environment = local.environment
  label_order = local.label_order
  location    = local.location

}

##-----------------------------------------------------------------------------
## Vnet
##-----------------------------------------------------------------------------
module "vnet" {
  source              = "terraform-az-modules/vnet/azurerm"
  version             = "1.0.4"
  name                = local.name
  environment         = local.environment
  label_order         = local.label_order
  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.resource_group_location
  address_spaces      = ["10.0.0.0/16"]

}

##-----------------------------------------------------------------------------
## Subnet
##-----------------------------------------------------------------------------
module "subnet" {
  source               = "terraform-az-modules/subnet/azurerm"
  version              = "1.0.3"
  environment          = local.environment
  resource_group_name  = module.resource_group.resource_group_name
  location             = module.resource_group.resource_group_location
  virtual_network_name = module.vnet.vnet_name

  subnets = [
    {
      name            = "subnet1"
      subnet_prefixes = ["10.0.1.0/24"]
    }
  ]

  enable_route_table = false
}

##-----------------------------------------------------------------------------
## Log Analytics
##-----------------------------------------------------------------------------
module "log-analytics" {
  source                      = "terraform-az-modules/log-analytics/azurerm"
  version                     = "2.1.0"
  name                        = local.name
  environment                 = local.environment
  label_order                 = local.label_order
  log_analytics_workspace_sku = "PerGB2018"
  resource_group_name         = module.resource_group.resource_group_name
  location                    = module.resource_group.resource_group_location

}

##-----------------------------------------------------------------------------
## Private DNS Zone (privatelink.servicebus.windows.net)
##-----------------------------------------------------------------------------
module "private_dns_zone" {
  source              = "terraform-az-modules/private-dns/azurerm"
  version             = "1.0.8"
  name                = local.name
  environment         = local.environment
  resource_group_name = module.resource_group.resource_group_name
  label_order         = local.label_order

  private_dns_config = [
    {
      resource_type = "azure_relay"
      vnet_ids      = [module.vnet.vnet_id]
    }
  ]
}

##-----------------------------------------------------------------------------
## Azure Relay
##-----------------------------------------------------------------------------
module "azure_relay" {
  source              = "../.."
  name                = local.name
  environment         = local.environment
  label_order         = local.label_order
  location            = module.resource_group.resource_group_location
  resource_group_name = module.resource_group.resource_group_name

  ## Namespace-level policy for operators; apps get entity-level rules below.
  authorization_rules = {
    ops-manage = {
      listen = true
      send   = true
      manage = true
    }
  }

  hybrid_connections = {
    reporting-db = {
      user_metadata = "On-premises reporting database listener"

      authorization_rules = {
        listener = { listen = true }
        sender   = { send = true }
      }
    }
  }

  enable_private_endpoint = true
  subnet_id               = module.subnet.subnet_ids.subnet1
  private_dns_zone_ids    = module.private_dns_zone.private_dns_zone_ids.azure_relay

  enable_diagnostic          = true
  log_analytics_workspace_id = module.log-analytics.workspace_id
}
