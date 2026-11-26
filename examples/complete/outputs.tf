output "relay_namespace_id" {
  description = "The Relay namespace ID."
  value       = module.azure_relay.relay_namespace_id
}

output "relay_namespace_fqdn" {
  description = "The Relay namespace FQDN."
  value       = module.azure_relay.relay_namespace_fqdn
}

output "hybrid_connection_ids" {
  description = "Hybrid connection IDs keyed by hybrid connection name."
  value       = module.azure_relay.hybrid_connection_ids
}

output "private_endpoint_ip_address" {
  description = "The private IP address of the Relay namespace private endpoint."
  value       = module.azure_relay.private_endpoint_ip_address
}

output "hybrid_connection_authorization_rules" {
  description = "Hybrid connection authorization rules with keys and connection strings."
  value       = module.azure_relay.hybrid_connection_authorization_rules
  sensitive   = true
}
