resource "azurerm_service_plan" "asp" {

  name                = var.asp_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = merge(var.default_tags, var.custom_tags)
  sku_name            = var.sku_size
  os_type             = "Linux"
}

resource "azurerm_linux_web_app" "app" {

  for_each            = var.app_services

    name                            = each.value.name
    location                        = each.value.location
    resource_group_name             = azurerm_service_plan.asp.resource_group_name
    service_plan_id                 = azurerm_service_plan.asp.id
    tags                            = merge(var.default_tags, var.custom_tags)
    https_only                      = true
    client_certificate_enabled      = false

    site_config {

        always_on             = each.value.site_config.always_on
        ftps_state            = each.value.site_config.ftps_state
        http2_enabled         = each.value.site_config.http2_enabled


        dynamic "ip_restriction" {
          for_each = var.ip_restrictions
          content {
            name       = ip_restriction.value.name
            ip_address = ip_restriction.value.ip_address
            action     = ip_restriction.value.action
            priority   = ip_restriction.value.priority
          }
        }

        ip_restriction {
          service_tag = "AzureCloud"
          action      = "Allow"
          priority    = "99"
          name        = "AllowAzureCloud"
        }

        managed_pipeline_mode = each.value.site_config.managed_pipeline_mode
        minimum_tls_version   = each.value.site_config.minimum_tls_version
        health_check_path     = each.value.site_config.health_check_path
    }
    
    app_settings = {
        PORT                                = each.value.app_settings.PORT
        DOCKER_IMAGE                        = each.value.app_settings.DOCKER_IMAGE 
        WEBSITES_CONTAINER_START_TIME_LIMIT = each.value.app_settings.WEBSITES_CONTAINER_START_TIME_LIMIT
        DOCKER_ENABLE_CI                    = each.value.app_settings.DOCKER_ENABLE_CI
        #DOCKER_REGISTRY_SERVER_PASSWORD    = each.value.DOCKER_REGISTRY_SERVER_PASSWORD
        DOCKER_REGISTRY_SERVER_URL          = each.value.app_settings.DOCKER_REGISTRY_SERVER_URL
        DOCKER_REGISTRY_SERVER_USERNAME     = each.value.app_settings.DOCKER_REGISTRY_SERVER_USERNAME
    }
    backup {  
      name = "${each.value.name} Backup"
      schedule {  
            frequency_interval          = var.frequency_interval
            frequency_unit              = var.frequency_unit
            keep_at_least_one_backup    = var.keep_at_least_one_backup
            retention_period_days       = var.retention_period_in_days
      }  
      storage_account_url = var.storage_account_url  
    }   
}