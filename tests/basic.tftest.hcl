## Mocked provider: tests run offline without Azure credentials.
mock_provider "azurerm" {}

variables {
  name                = "relay"
  environment         = "test"
  location            = "centralindia"
  resource_group_name = "rg-relay-test"

  hybrid_connections = {
    reporting-db = {
      authorization_rules = {
        listener = { listen = true }
        sender   = { send = true }
      }
    }
  }
}

run "validate_module" {
  command = plan

  assert {
    condition     = azurerm_relay_namespace.main[0].name == "relay-relay-test-inci"
    error_message = "Relay namespace name must follow the labels naming convention."
  }

  assert {
    condition     = azurerm_relay_hybrid_connection.main["reporting-db"].requires_client_authorization
    error_message = "Hybrid connections must require client authorization by default."
  }

  assert {
    condition     = length(azurerm_relay_hybrid_connection_authorization_rule.main) == 2
    error_message = "Expected one authorization rule per hybrid connection rule."
  }

  assert {
    condition     = length(azurerm_private_endpoint.pep) == 0 && length(azurerm_monitor_diagnostic_setting.main) == 0
    error_message = "Private endpoint and diagnostics must be off by default."
  }
}

run "disabled_creates_nothing" {
  command = plan

  variables {
    enabled = false
  }

  assert {
    condition     = length(azurerm_relay_namespace.main) == 0 && length(azurerm_relay_hybrid_connection.main) == 0
    error_message = "enabled = false must not create resources."
  }
}

run "private_endpoint_requires_subnet" {
  command = plan

  variables {
    enable_private_endpoint = true
  }

  expect_failures = [var.subnet_id]
}

run "diagnostic_requires_destination" {
  command = plan

  variables {
    enable_diagnostic = true
  }

  expect_failures = [var.log_analytics_workspace_id]
}

run "manage_requires_listen_and_send" {
  command = plan

  variables {
    authorization_rules = {
      bad = { manage = true }
    }
  }

  expect_failures = [var.authorization_rules]
}
