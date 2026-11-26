output "relay_namespace_name" {
  description = "The Relay namespace name."
  value       = module.azure_relay.relay_namespace_name
}

output "hybrid_connection_ids" {
  description = "Hybrid connection IDs keyed by hybrid connection name."
  value       = module.azure_relay.hybrid_connection_ids
}
