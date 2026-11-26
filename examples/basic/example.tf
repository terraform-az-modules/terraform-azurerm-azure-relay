provider "azurerm" {
  features {}
}

locals {
  name        = "app"
  environment = "dev"
  location    = "centralindia"
}

##-----------------------------------------------------------------------------
## Resource Group
##-----------------------------------------------------------------------------
module "resource_group" {
  source      = "terraform-az-modules/resource-group/azurerm"
  version     = "1.0.4"
  name        = local.name
  environment = local.environment
  location    = local.location
}

##-----------------------------------------------------------------------------
## Azure Relay
##-----------------------------------------------------------------------------
module "azure_relay" {
  source              = "../../"
  name                = local.name
  environment         = local.environment
  location            = module.resource_group.resource_group_location
  resource_group_name = module.resource_group.resource_group_name

  hybrid_connections = {
    reporting-db = {}
  }
}
