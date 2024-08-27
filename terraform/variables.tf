# variables.tf

variable "vps_product_id" {
  description = "Product ID for Contabo VPS"
  default     = "V48"
}

variable "region" {
  description = "Region for Contabo resources. Options: EU, US-central, US-east, US-west, SIN"
  default     = "EU"
}

