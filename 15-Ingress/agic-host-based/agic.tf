resource "azurerm_resource_group" "rg" {
  name     = "rg-demo"
  location = "Central India"
}

resource "azurerm_public_ip" "pip" {

  name                = "appgw-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  allocation_method = "Static"
  sku               = "Standard"

}

resource "azurerm_subnet" "appgw" {

  name                 = "appgw-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.main.name

  address_prefixes = [
    "10.0.2.0/24"
  ]
}


resource "azurerm_application_gateway" "appgw" {

  name                = "demo-appgw"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "gateway-ip"
    subnet_id = azurerm_subnet.appgw.id
  }

  frontend_port {
    name = "http"
    port = 80
    
  }

  frontend_ip_configuration {

    name                 = "public-ip"

    public_ip_address_id = azurerm_public_ip.pip.id

  }

  backend_address_pool {
    name = "backend"
  }

  backend_http_settings {

    name                  = "http-setting"

    cookie_based_affinity = "Disabled"

    port                  = 80

    protocol              = "Http"

    request_timeout       = 30

  }

  http_listener {

    name                           = "listener"

    frontend_ip_configuration_name = "public-ip"

    frontend_port_name             = "http"

    protocol                       = "Http"

  }

  request_routing_rule {

    name                       = "rule"

    priority                   = 1

    rule_type                  = "Basic"

    http_listener_name         = "listener"

    backend_address_pool_name  = "backend"

    backend_http_settings_name = "http-setting"

  }

}




resource "azurerm_kubernetes_cluster" "aks" {

  name                = "aks-demo"

  location            = azurerm_resource_group.rg.location

  resource_group_name = azurerm_resource_group.rg.name

  dns_prefix          = "aks"

  default_node_pool {

    name       = "system"

    node_count = 2

    vm_size    = "Standard_DS2_v2"

  }

  identity {

    type = "SystemAssigned"

  }

  ingress_application_gateway {

      gateway_id = azurerm_application_gateway.appgw.id

  }

}