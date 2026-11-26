##-----------------------------------------------------------------------------
## Locals
##-----------------------------------------------------------------------------
locals {
  name = var.custom_name != null ? var.custom_name : module.labels.id

  ## Flatten per-hybrid-connection rules into one map keyed "<hc>/<rule>" so
  ## for_each keys stay stable when connections or rules are added/removed.
  hybrid_connection_authorization_rules = merge([
    for hc_key, hc in var.hybrid_connections : {
      for rule_key, rule in hc.authorization_rules : "${hc_key}/${rule_key}" => merge(rule, {
        name                  = rule_key
        hybrid_connection_key = hc_key
      })
    }
  ]...)
}
