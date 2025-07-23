#azure_vnet
resource "azurerm_virtual_network" "bap_vnet" {
  name                = "bap-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.0.0.0/16"] # update as per your network
  tags = {
    name = "bap-vnet"
  }
}

#Subnet1 - azure_firewall_subnet
resource "azurerm_subnet" "azure_firewall_subnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = ["10.0.1.0/26"]
}

#Subnet2 - azure_firewall_mgmt_subnet
resource "azurerm_subnet" "azure_firewall_mgmt_subnet" {
  name                 = "AzureFirewallManagementSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = ["10.0.1.64/26"]
}

#Subnet3 - graphapi_subnet
resource "azurerm_subnet" "graphapi_subnet" {
  name                 = "bap-subnet-graphapi"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = ["10.0.3.0/24"]
}

#Subnet4 - openai_subnet
resource "azurerm_subnet" "openai_subnet" {
  name                 = "bap-subnet-openai"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = ["10.0.2.0/24"]
}

#Subnet5 - pgsql_subnet
resource "azurerm_subnet" "pgsql_subnet" {
  name                 = "bap-subnet-pgsql"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = ["10.0.0.0/24"]
  service_endpoints = ["Microsoft.Storage"]

  delegation {
    name = "dlg-Microsoft.DBforPostgreSQL-flexibleServers"

    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

#Subnet6 - appgw_subnet
resource "azurerm_subnet" "appgw_subnet" {
  name                 = "bap-subnet-appgw"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = ["10.0.4.0/24"]
}

#Security Group1 - bap-vnet-nsg
resource "azurerm_network_security_group" "vnet_nsg" {
  name                = "bap-vnet-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  security_rule       = []  # You will fill this after import
  tags = {
    name = "bap-vnet-nsg"
  }
}

#Security Group2 - bap-subnet-pgsql-nsg
resource "azurerm_network_security_group" "pgsql_subnet_nsg" {
  name                = "bap-subnet-pgsql-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  security_rule       = [
        {
            access                                     = "Allow"
            description                                = null
            destination_address_prefix                 = "*"
            destination_address_prefixes               = []
            destination_application_security_group_ids = []
            destination_port_range                     = null
            destination_port_ranges                    = ["5432","6432",]
            direction                                  = "Outbound"
            name                                       = "AllowTagCustomAnyOutbound"
            priority                                   = 110
            protocol                                   = "*"
            source_address_prefix                      = "Internet"
            source_address_prefixes                    = []
            source_application_security_group_ids      = []
            source_port_range                          = null
            source_port_ranges                         = ["5432","6432",]
        },
        {
            access                                     = "Allow"
            description                                = null
            destination_address_prefix                 = "*"
            destination_address_prefixes               = []
            destination_application_security_group_ids = []
            destination_port_range                     = "5432"
            destination_port_ranges                    = []
            direction                                  = "Inbound"
            name                                       = "AllowVNetInbound"
            priority                                   = 100
            protocol                                   = "Tcp"
            source_address_prefix                      = "14.97.228.214"
            source_address_prefixes                    = []
            source_application_security_group_ids      = []
            source_port_range                          = null
            source_port_ranges                         = ["5432","6432",]
        },
    ]
    tags                = {
        "name" = "bap-subnet-pgsql-nsg"
    }
}

#Security Group3 - bap-subnet-openai-nsg
resource "azurerm_network_security_group" "openai_subnet_nsg" {
  name                = "bap-subnet-openai-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  security_rule       = [
        {
            access                                     = "Allow"
            description                                = null
            destination_address_prefix                 = "*"
            destination_address_prefixes               = []
            destination_application_security_group_ids = []
            destination_port_range                     = "443"
            destination_port_ranges                    = []
            direction                                  = "Inbound"
            name                                       = "AllowAnyCustom443Inbound"
            priority                                   = 100
            protocol                                   = "Tcp"
            source_address_prefix                      = "*"
            source_address_prefixes                    = []
            source_application_security_group_ids      = []
            source_port_range                          = "*"
            source_port_ranges                         = []
        },
        {
            access                                     = "Allow"
            description                                = null
            destination_address_prefix                 = "*"
            destination_address_prefixes               = []
            destination_application_security_group_ids = []
            destination_port_range                     = "443"
            destination_port_ranges                    = []
            direction                                  = "Outbound"
            name                                       = "AllowAnyHTTPSOutbound"
            priority                                   = 110
            protocol                                   = "Tcp"
            source_address_prefix                      = "*"
            source_address_prefixes                    = []
            source_application_security_group_ids      = []
            source_port_range                          = "*"
            source_port_ranges                         = []
        },
    ]
    tags                = {
        "name" = "bap-subnet-openai-nsg"
    }
}

#Security Group4 - bap-subnet-graphapi-nsg & VM CICD server
resource "azurerm_network_security_group" "graphapi_subnet_nsg" {
  name                = "bap-subnet-graphapi-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  security_rule {
    name                       = "AllowCidrBlockSSHInbound-zucivpn1"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "14.97.228.214"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowCidrBlockCustom8080Inbound-zucivpn2"
    priority                   = 140
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "123.63.230.249"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowCidrBlockCustomAnyInbound-zucivpn3"
    priority                   = 150
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "14.143.71.14"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowCidrBlockCustomAnyInbound"
    priority                   = 160
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "183.82.241.114"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowCidrBlockCustom8080Inbound"
    priority                   = 170
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "124.123.83.202"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowMyIpAddressSSHInbound"
    priority                   = 180
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "115.99.45.122"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowAnyCustom9000Inbound"
    priority                   = 190
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    name = "bap-subnet-graphapi-nsg"
  }
}

#Security Group5 - bap-subnet-appgw-nsg
resource "azurerm_network_security_group" "appgw_subnet_nsg" {
  name                = "bap-subnet-appgw-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  security_rule       = [
        {
            access                                     = "Allow"
            description                                = null
            destination_address_prefix                 = "*"
            destination_address_prefixes               = []
            destination_application_security_group_ids = []
            destination_port_range                     = "65200-65535"
            destination_port_ranges                    = []
            direction                                  = "Inbound"
            name                                       = "AllowAnyCustom65200-65535Inbound"
            priority                                   = 100
            protocol                                   = "*"
            source_address_prefix                      = "*"
            source_address_prefixes                    = []
            source_application_security_group_ids      = []
            source_port_range                          = "*"
            source_port_ranges                         = []
        },
    ]
    tags                = {
        "name" = "bap-subnet-appgw-nsg"
    }
}

#Private link1 - bap-pgsql-db
resource "azurerm_private_dns_zone" "pgsql_dns_zone" {
  name                = "bap-pgsql-db.private.postgres.database.azure.com"
  resource_group_name = var.resource_group_name
}

#Private link2 - bap-openai
resource "azurerm_private_dns_zone" "openai_dns_zone" {
  name                = "privatelink.openai.azure.com"
  resource_group_name = var.resource_group_name
}

#Vnet link1 - bap-pgsql-db
resource "azurerm_private_dns_zone_virtual_network_link" "pgsql_vnet_link" {
  name                  = "em7o3ibozvsp2"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.pgsql_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.bap_vnet.id
  registration_enabled  = false
}

#Vnet link2 - bap-openai
resource "azurerm_private_dns_zone_virtual_network_link" "openai_vnet_link" {
  name                  = "mvnkt2pjmzqoi"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.openai_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.bap_vnet.id
  registration_enabled  = false
}

#Storage Account1 - bapstorageblob
resource "azurerm_storage_account" "blob_storage" {
  name                     = "bapstorageblob"
  resource_group_name      = "Borderless-access-pilot"
  location                 = "eastus"
  account_tier             = "Standard"
  account_kind             = "StorageV2"
  account_replication_type = "LRS"
  access_tier              = "Hot"

  https_traffic_only_enabled         = true
  public_network_access_enabled      = true
  shared_access_key_enabled          = true
  cross_tenant_replication_enabled   = false
  infrastructure_encryption_enabled  = false
  is_hns_enabled                     = false
  large_file_share_enabled           = true
  local_user_enabled                 = true
  nfsv3_enabled                      = false
  sftp_enabled                       = false
  min_tls_version                    = "TLS1_2"
  default_to_oauth_authentication    = false
  allow_nested_items_to_be_public    = false
  dns_endpoint_type                  = "Standard"
  queue_encryption_key_type          = "Account"  # avoid replacement
  table_encryption_key_type          = "Account"  # avoid replacement

  blob_properties {
    change_feed_enabled        = false
    versioning_enabled         = false
    last_access_time_enabled   = false

    delete_retention_policy {
      days                     = 7
      permanent_delete_enabled = false
    }

    container_delete_retention_policy {
      days = 7
    }
  }

  queue_properties {
    logging {
      delete                = true
      read                  = true
      write                 = true
      version               = "1.0"
      retention_policy_days = 7
    }

    hour_metrics {
      enabled               = false
      include_apis          = false
      version               = "1.0"
      retention_policy_days = 7
    }

    minute_metrics {
      enabled               = true
      include_apis          = true
      version               = "1.0"
      retention_policy_days = 7
    }
  }

  share_properties {
    retention_policy {
      days = 7
    }
  }

  tags = {
    name = "bap-storageblob"
  }
}

#Azure Data Factory -bap-datafact
resource "azurerm_data_factory" "bap_data_factory" {
  name                = "bap-datafact"
  location            = var.location
  resource_group_name = var.resource_group_name
  public_network_enabled           = true
  identity {
    type = "SystemAssigned"
  }
  tags                             = {
        "name" = "bap-datafact"
    }
}

#Azure Log Analytics workspace -bap-loganalytics
resource "azurerm_log_analytics_workspace" "bap_log_analytics" {
  name                = "bap-loganalytics-logs"
  location            = var.location
  resource_group_name = var.resource_group_name

  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    name = "bap-loganalytics-logs"
  }
}

#Event Grid Topic -bap-eventgridtopic
resource "azurerm_eventgrid_topic" "bap_eventgrid_topic" {
  name                = "bap-eventgridtopic"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = {
    name = "bap-eventgridtopic"
  }
}

#Event Grid Topic Subscription -bap-eventgridsub-app
resource "azurerm_eventgrid_event_subscription" "bap_eventgridsub_app" {
  name  = "bap-eventgridsub-app"
  scope = azurerm_eventgrid_topic.bap_eventgrid_topic.id

  webhook_endpoint {
    url = "https://eventgrid-listener.wittyforest-5fea1062.eastus.azurecontainerapps.io/eventgrid"
    max_events_per_batch            = 1
    preferred_batch_size_in_kilobytes = 64
  }

  event_delivery_schema = "EventGridSchema"

  retry_policy {
    max_delivery_attempts = 30
    event_time_to_live    = 1440
  }
  advanced_filtering_on_arrays_enabled = true

  depends_on = [
    azurerm_eventgrid_topic.bap_eventgrid_topic
  ]
}
#Azure Function service plan -EastUSLinuxDynamicPlan
resource "azurerm_service_plan" "plan" {
  name                = "EastUSLinuxDynamicPlan"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = "Y1"
  tags = {
    name = "bap-function-serviceplan"
  }
}

#Azure Function  -HttpTrigger-email
resource "azurerm_linux_function_app" "bap_function" {
  name                       = "HttpTrigger-email"
  location                   = var.location
  resource_group_name        = var.resource_group_name

  service_plan_id            = azurerm_service_plan.plan.id
  storage_account_name       = azurerm_storage_account.blob_storage.name
  storage_account_access_key = azurerm_storage_account.blob_storage.primary_access_key

  site_config {
    application_stack {
      python_version = "3.11"
    }
  }
  lifecycle {
    ignore_changes = [
      tags["hidden-link: /app-insights-resource-id"]
    ]
  }
  https_only = true  # More secure (recommended)

  tags = {
    name = "bap-function"
  }
}

resource "azurerm_postgresql_flexible_server" "bap_pgsql" {
  name                = "bap-pgsqlfs-db"
  location            = var.location
  resource_group_name = var.resource_group_name
  zone                   = "2"
  tags = {
    name = "bap-pgsqlfs-db"
  }
  # additional required values added after import
}

resource "azurerm_key_vault" "bap_kv" {
  name                = "bap-keyvault-app"
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id       = var.tenant_id
  sku_name        = "standard" 
  enable_rbac_authorization  = true

  tags = {
    name = "bap-keyvault-app"
  }
}

resource "azurerm_container_registry" "bap_acr" {
  name                = "bapacr"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku  = "Basic"
  admin_enabled       = true

  tags = {
    name = "bap-acr"
  }
  }

resource "azurerm_cognitive_account" "bap_openai" {
  name                = "bap-openai"
  location            = var.location
  resource_group_name = var.resource_group_name
  kind                = "OpenAI"
  sku_name            = "S0"
  custom_subdomain_name       = "bap-openai"
  dynamic_throttling_enabled  = false
  tags = {
    name = "bap-openai"
  }
  network_acls {
    default_action = "Allow"
    ip_rules       = []
  }
}

