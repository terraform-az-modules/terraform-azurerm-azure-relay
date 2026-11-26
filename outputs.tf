##-----------------------------------------------------------------------------
## Outputs
##-----------------------------------------------------------------------------
output "relay_namespace_id" {
  description = "The Relay namespace ID."
  value       = try(azurerm_relay_namespace.main[0].id, null)
}

output "relay_namespace_name" {
  description = "The Relay namespace name."
  value       = try(azurerm_relay_namespace.main[0].name, null)
}

output "relay_namespace_fqdn" {
  description = "The Relay namespace FQDN that listeners and senders connect to."
  value       = try("${azurerm_relay_namespace.main[0].name}.servicebus.windows.net", null)
}

output "hybrid_connection_ids" {
  description = "Hybrid connection IDs keyed by hybrid connection name."
  value       = { for k, v in azurerm_relay_hybrid_connection.main : k => v.id }
}

output "namespace_authorization_rules" {
  description = "Namespace authorization rules keyed by rule name, with keys and connection strings."
  sensitive   = true
  value = {
    for k, v in azurerm_relay_namespace_authorization_rule.main : k => {
      id                          = v.id
      primary_key                 = v.primary_key
      secondary_key               = v.secondary_key
      primary_connection_string   = v.primary_connection_string
      secondary_connection_string = v.secondary_connection_string
    }
  }
}

output "hybrid_connection_authorization_rules" {
  description = "Hybrid connection authorization rules keyed by \"<hybrid connection>/<rule>\", with keys and connection strings."
  sensitive   = true
  value = {
    for k, v in azurerm_relay_hybrid_connection_authorization_rule.main : k => {
      id                          = v.id
      primary_key                 = v.primary_key
      secondary_key               = v.secondary_key
      primary_connection_string   = v.primary_connection_string
      secondary_connection_string = v.secondary_connection_string
    }
  }
}

output "role_assignment_ids" {
  description = "Role assignment IDs keyed by alias."
  value       = { for k, v in azurerm_role_assignment.main : k => v.id }
}

output "private_endpoint_id" {
  description = "The private endpoint ID."
  value       = try(azurerm_private_endpoint.pep[0].id, null)
}

output "private_endpoint_ip_address" {
  description = "The private IP address of the Relay namespace private endpoint."
  value       = try(azurerm_private_endpoint.pep[0].private_service_connection[0].private_ip_address, null)
}
