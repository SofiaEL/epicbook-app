output "public_ip" {
  value = azurerm_public_ip.main.ip_address
}

output "admin_user" {
  value = var.admin_username
}

output "db_host" {
  value = azurerm_mysql_flexible_server.main.fqdn
}