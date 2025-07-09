terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "5.0.0"
    }
  }
}

provider "vault" {
  address = "https://vault.vovsike.co.uk"
}