output "app_service_default_hostname" {
  description = "The default hostname of the App Service"
  value       =  values(azurerm_linux_web_app.app).*.default_hostname

}