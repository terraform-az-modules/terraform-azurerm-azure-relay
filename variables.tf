##-----------------------------------------------------------------------------
## Naming convention
##-----------------------------------------------------------------------------
variable "custom_name" {
  type        = string
  default     = null
  description = "Override default naming convention. Used in place of the generated `name-environment-location` id for every resource name this module derives."
}

variable "resource_position_prefix" {
  type        = bool
  default     = true
  description = <<EOT
Controls the placement of the resource type keyword (e.g., "relay", "pe") in the resource name.

- If true, the keyword is prepended: "relay-core-dev-inci".
- If false, the keyword is appended: "core-dev-inci-relay".

This helps maintain naming consistency based on organizational preferences.
EOT
}

##-----------------------------------------------------------------------------
## Labels
##-----------------------------------------------------------------------------
variable "name" {
  type        = string
  default     = "core"
  description = "Name (e.g. `app` or `cluster`)."
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Environment (e.g. `prod`, `dev`, `staging`)."
}

variable "location" {
  type        = string
  description = "The location/region where the Relay namespace is created. Changing this forces a new resource to be created."
}

variable "label_order" {
  type        = list(string)
  default     = ["name", "environment", "location"]
  description = "The order of labels used to construct resource names or tags. If not specified, defaults to ['name', 'environment', 'location']."
}

variable "managedby" {
  type        = string
  default     = "terraform-az-modules"
  description = "ManagedBy, eg 'terraform-az-modules'."
}

variable "extra_tags" {
  type        = map(string)
  default     = null
  description = "Variable to pass extra tags."
}

variable "repository" {
  type        = string
  default     = "https://github.com/terraform-az-modules/terraform-azurerm-azure-relay"
  description = "Terraform current module repo"

  validation {
    # regex(...) fails if it cannot find a match
    condition     = can(regex("^https://", var.repository))
    error_message = "The module-repo value must be a valid Git repo link."
  }
}

variable "deployment_mode" {
  type        = string
  default     = "terraform"
  description = "Specifies how the infrastructure/resource is deployed"
}

##-----------------------------------------------------------------------------
## Global Variables
##-----------------------------------------------------------------------------
variable "enabled" {
  type        = bool
  default     = true
  description = "Set to false to prevent the module from creating any resources."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to create the Relay namespace."
}

##-----------------------------------------------------------------------------
## Relay Namespace
##-----------------------------------------------------------------------------
variable "sku_name" {
  type        = string
  default     = "Standard"
  description = "The SKU of the Relay namespace. Azure Relay only offers `Standard`."

  validation {
    condition     = var.sku_name == "Standard"
    error_message = "sku_name must be Standard (the only SKU Azure Relay offers)."
  }
}

variable "authorization_rules" {
  type = map(object({
    listen = optional(bool, false)
    send   = optional(bool, false)
    manage = optional(bool, false)
  }))
  default     = {}
  description = <<EOT
Namespace-level shared access policies keyed by rule name. Azure creates `RootManageSharedAccessKey` automatically; prefer narrower rules (or Entra ID `role_assignments`) for applications.

Each object supports:
- listen: (Optional) Grant Listen rights. Defaults to false.
- send:   (Optional) Grant Send rights. Defaults to false.
- manage: (Optional) Grant Manage rights. Requires listen and send. Defaults to false.
EOT

  validation {
    condition = alltrue([
      for rule in values(var.authorization_rules) :
      (rule.listen || rule.send || rule.manage) && (!rule.manage || (rule.listen && rule.send))
    ])
    error_message = "Each authorization rule must grant at least one right, and manage requires listen and send."
  }
}

variable "hybrid_connections" {
  type = map(object({
    requires_client_authorization = optional(bool, true)
    user_metadata                 = optional(string)

    authorization_rules = optional(map(object({
      listen = optional(bool, false)
      send   = optional(bool, false)
      manage = optional(bool, false)
    })), {})
  }))
  default     = {}
  description = <<EOT
Hybrid connections keyed by hybrid connection name. The key is used verbatim as the entity name that listeners and senders connect to.

Each object supports:
- requires_client_authorization: (Optional) Require senders to present a token. Defaults to true; set false only for intentionally anonymous senders.
- user_metadata:                 (Optional) Free-form metadata, e.g. the on-premises endpoint the listener forwards to.
- authorization_rules:           (Optional) Entity-level shared access policies keyed by rule name, same shape as `authorization_rules`.
EOT

  validation {
    condition = alltrue([
      for key in keys(var.hybrid_connections) :
      can(regex("^[A-Za-z0-9][A-Za-z0-9._-]{0,259}$", key))
    ])
    error_message = "Hybrid connection names must start with a letter or number and contain only letters, numbers, periods, hyphens and underscores (max 260 characters)."
  }

  validation {
    condition = alltrue(flatten([
      for hc in values(var.hybrid_connections) : [
        for rule in values(hc.authorization_rules) :
        (rule.listen || rule.send || rule.manage) && (!rule.manage || (rule.listen && rule.send))
      ]
    ]))
    error_message = "Each hybrid connection authorization rule must grant at least one right, and manage requires listen and send."
  }
}

variable "role_assignments" {
  type = map(object({
    principal_id          = string
    role_definition_name  = string
    hybrid_connection_key = optional(string)
  }))
  default     = {}
  description = <<EOT
Entra ID (RBAC) role assignments keyed by a stable alias. Preferred over shared access keys for workloads with a managed identity.

Each object supports:
- principal_id:          (Required) Object ID of the user, group, service principal or managed identity.
- role_definition_name:  (Required) Built-in role, typically `Azure Relay Listener`, `Azure Relay Sender` or `Azure Relay Owner`.
- hybrid_connection_key: (Optional) Key in `hybrid_connections` to scope the assignment to a single hybrid connection. Defaults to the namespace scope.
EOT

  validation {
    condition = alltrue([
      for ra in values(var.role_assignments) :
      ra.hybrid_connection_key == null ? true : contains(keys(var.hybrid_connections), ra.hybrid_connection_key)
    ])
    error_message = "role_assignments.hybrid_connection_key must match a key in hybrid_connections."
  }
}

##-----------------------------------------------------------------------------
## Private Endpoint
##-----------------------------------------------------------------------------
variable "enable_private_endpoint" {
  type        = bool
  default     = false
  description = "Create a private endpoint for the Relay namespace."
}

variable "subnet_id" {
  type        = string
  default     = null
  description = "Subnet ID for the private endpoint. Required when enable_private_endpoint is true."

  validation {
    condition     = !var.enable_private_endpoint || var.subnet_id != null
    error_message = "subnet_id is required when enable_private_endpoint is true."
  }
}

variable "private_dns_zone_ids" {
  type        = string
  default     = null
  description = "The ID of the `privatelink.servicebus.windows.net` private DNS zone. When null, no DNS zone group is attached to the private endpoint."
}

##-----------------------------------------------------------------------------
## Diagnostic Settings
##-----------------------------------------------------------------------------
variable "enable_diagnostic" {
  type        = bool
  default     = false
  description = "Enable diagnostic settings for the Relay namespace. Requires at least one destination."
}

variable "log_analytics_workspace_id" {
  type        = string
  default     = null
  description = "Log Analytics Workspace ID for diagnostics."

  validation {
    condition     = !var.enable_diagnostic || var.log_analytics_workspace_id != null || var.storage_account_id != null || var.eventhub_authorization_rule_id != null
    error_message = "enable_diagnostic requires log_analytics_workspace_id, storage_account_id or eventhub_authorization_rule_id."
  }
}

variable "storage_account_id" {
  type        = string
  default     = null
  description = "Storage Account ID for diagnostics."
}

variable "eventhub_name" {
  type        = string
  default     = null
  description = "Event Hub name for diagnostics."
}

variable "eventhub_authorization_rule_id" {
  type        = string
  default     = null
  description = "Event Hub authorization rule ID for diagnostics."
}

variable "metric_enabled" {
  type        = bool
  default     = true
  description = "Boolean flag to specify whether Metrics should be enabled. Defaults to true."
}

variable "log_enabled" {
  type        = bool
  default     = true
  description = "Boolean flag to specify whether Logs should be enabled. Defaults to true."
}
