provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
    name = "terraform-tutorial-test"
    location = "westus3"
}