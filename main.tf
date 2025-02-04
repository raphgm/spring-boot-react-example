resource "azurerm_linux_web_app" "backend" {
  name                = "backend-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_service_plan.asp.location
  service_plan_id     = azurerm_service_plan.asp.id
  https_only          = true
  public_network_access_enabled = true

  site_config {
    always_on = true
    
    application_stack {
      docker_image_name   = "${var.docker_username}/${var.docker_backend_image}:${coalesce(var.docker_image_tag, "latest")}"
      docker_registry_url = var.docker_registry_url != "" ? "https://${trimsuffix(var.docker_registry_url, "/")}" : "https://docker.io"
    }

    cors {
      allowed_origins     = ["*"]
      support_credentials = false
    }

    ip_restriction {
      action      = "Allow"
      ip_address  = var.allowed_ip_range
      name        = "RestrictedAccess"
      priority    = 100
    }
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "DOCKER_REGISTRY_USERNAME"           = var.docker_registry_username
    "DOCKER_REGISTRY_PASSWORD"           = var.docker_registry_password
  }

  auth_settings {
    enabled = true
    default_provider = "AzureActiveDirectory"
    active_directory {
      client_id     = var.azure_client_id
      client_secret = var.azure_client_secret
    }
  }
}

# Frontend Web App (Corrected)
resource "azurerm_linux_web_app" "frontend" {
  name                = "${var.project_name}-frontend-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_service_plan.asp.location
  service_plan_id     = azurerm_service_plan.asp.id

  site_config {
    always_on = true
    application_stack {
      docker_image_name   = "${var.docker_username}/${var.docker_frontend_image}:${coalesce(var.docker_image_tag, "latest")}"
      docker_registry_url = var.docker_registry_url != "" ? "https://${trimsuffix(var.docker_registry_url, "/")}" : "https://docker.io"
    }
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "DOCKER_REGISTRY_USERNAME"           = var.docker_registry_username
    "DOCKER_REGISTRY_PASSWORD"           = var.docker_registry_password
  }
}

resource "azurerm_role_assignment" "webapp_contributor" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_linux_web_app.backend.identity[0].principal_id
}

# Assign roles to user groups
resource "azurerm_role_assignment" "user_roles" {
  for_each             = toset(["27df6cf9-31dc-4045-84a0-1b241c36d64a"])
  principal_id         = each.value
  role_definition_name = "Reader"
  scope                = azurerm_resource_group.rg.id
}

# Assign roles to admin groups
resource "azurerm_role_assignment" "admin_roles" {
  for_each             = toset(["fe94c441-321d-442a-a76c-92831ea49178"])
  principal_id         = each.value
  role_definition_name = "Contributor"
  scope                = azurerm_resource_group.rg.id
}

# Create Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "workspace" {
  name                = "log-${var.project_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                = "PerGB2018"
  retention_in_days  = 30
  tags               = var.tags
}

# Enable diagnostic settings for the backend Linux Web App
resource "azurerm_monitor_diagnostic_setting" "backend_app_diagnostic" {
  name                       = "backend-app-diagnostic-setting"
  target_resource_id         = azurerm_linux_web_app.backend.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.workspace.id

  enabled_log {
    category = "AppServiceHTTPLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

//Configure autoscale settings for the App Service Plan
resource "azurerm_monitor_autoscale_setting" "app_service_auto_scale" {
  name                = "auto-scale-${var.project_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  target_resource_id  = azurerm_service_plan.asp.id

  profile {
    name = "defaultProfile"

    capacity {
      default = var.default_instance_count
      minimum = var.min_instance_count
      maximum = var.max_instance_count
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.asp.id
        time_grain        = "PT1M"
        statistic         = "Average"
        time_window       = "PT5M"
        time_aggregation  = "Average"
        operator          = "GreaterThan"
        threshold         = var.scale_up_threshold
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT${var.scale_cooldown_minutes}M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.asp.id
        time_grain        = "PT1M"
        statistic         = "Average"
        time_window       = "PT5M"
        time_aggregation  = "Average"
        operator          = "LessThan"
        threshold         = var.scale_down_threshold
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT${var.scale_cooldown_minutes}M"
      }
    }
  }
}

# Create Network Security Group
resource "azurerm_network_security_group" "app_nsg" {
  name                = "app-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range         = "*"
    destination_port_range    = "443"
    source_address_prefix     = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range         = "*"
    destination_port_range    = "80"
    source_address_prefix     = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_sql_server" "sql_server" {
  name                         = var.sql_server_name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_login
  administrator_login_password = var.sql_admin_password
}

resource "azurerm_sql_database" "sql_database" {
  name                = var.sql_database_name
  resource_group_name = var.resource_group_name
  location            = var.location
  server_name         = azurerm_sql_server.sql_server.name
  sku_name            = "S0"
}