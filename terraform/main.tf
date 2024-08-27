# terraform/main.tf
terraform {
  required_providers {
    contabo = {
      source = "contabo/contabo"
      version = ">= 0.1.26"
    }
  }
  backend "s3" {
    bucket         = "terraform-eth-zama-test"
    key            = "terra-contabo/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock-table-zama"
    access_key     = "XXX"
    secret_key     = "XXX"
  }
}

locals {
  ssh_public_key = file("/path/to_:you/pubkey.pub")
}

provider "contabo" {
  oauth2_client_id     = var.contabo_client_id
  oauth2_client_secret = var.contabo_client_secret
  oauth2_user          = var.contabo_user
  oauth2_pass          = var.contabo_password
}

variable "contabo_client_id" { sensitive = true }
variable "contabo_client_secret" { sensitive = true }
variable "contabo_user" { sensitive = true }
variable "contabo_password" { sensitive = true }
# variable "contabo_access_key" { sensitive = true }
# variable "contabo_secret_key" { sensitive = true }

# Create a secret for the SSH public key
resource "contabo_secret" "ssh_key" {
  name  = "ethereum_ssh_key"
  type  = "ssh"
  value = local.ssh_public_key
}

resource "contabo_instance" "ethereum_node" {
  count        = 3
  display_name = "eth-node-${count.index + 1}"
  product_id   = var.vps_product_id
  region       = var.region
  period       = 1
  ssh_keys     = [contabo_secret.ssh_key.id]
}

resource "contabo_instance" "monitoring" {
  display_name = "monitoring"
  product_id   = var.vps_product_id
  region       = var.region
  period       = 1
  ssh_keys     = [contabo_secret.ssh_key.id]
}

resource "contabo_private_network" "eth_network" {
  name        = "ethereum-network"
  description = "Private network for Ethereum nodes and monitoring"
  region      = var.region
  instance_ids = concat(
    [for node in contabo_instance.ethereum_node : node.id],
    [contabo_instance.monitoring.id]
  )
}

# # Optional: Output the public IPs of the instances for easy access
# output "ethereum_node_ips" {
#   value = [for node in contabo_instance.ethereum_node : node.ip_config[0].v4.ip]
# }

# output "monitoring_ip" {
#   value = contabo_instance.monitoring.ip_config[0].v4.ip
# }