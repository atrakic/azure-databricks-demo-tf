terraform {
  required_providers {
    azurerm = "~> 2.33"
    random  = {} #"~> 3.4.3"
  }
}

provider "azurerm" {
  features {}
}

variable "region" {
  type    = string
  default = "westeurope"
}

variable "tags" {
  type    = map(any)
  default = {}
}

resource "random_string" "naming" {
  special = false
  upper   = false
  length  = 6
}

data "azurerm_subscription" "current" {}

data "azurerm_client_config" "current" {}

data "external" "me" {
  program = ["az", "account", "show", "--query", "user"]
}

locals {
  prefix = "databricks${random_string.naming.result}"
  tags = {
    Region = var.region
    Owner  = lookup(data.external.me.result, "name")
  }
}

resource "azurerm_resource_group" "this" {
  name     = "${local.prefix}-rg"
  location = var.region
  tags     = merge(var.tags, local.tags)
}

resource "azurerm_databricks_workspace" "this" {
  name                        = "${local.prefix}-workspace"
  resource_group_name         = azurerm_resource_group.this.name
  location                    = azurerm_resource_group.this.location
  sku                         = "premium"
  managed_resource_group_name = "${local.prefix}-workspace-rg"
  tags                        = local.tags
}

output "databricks_host" {
  value = "https://${azurerm_databricks_workspace.this.workspace_url}/"
}

output "tags" {
  value = local.tags
}

output "location" {
  value = azurerm_resource_group.this.location
}

output "resource_group_name" {
  value = azurerm_resource_group.this.name
}
