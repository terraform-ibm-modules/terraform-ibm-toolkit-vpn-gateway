#####################################################
# VPN Gateway Configuration
# Copyright 2021 IBM
#####################################################

output "ids" {
  value = var.provision ? ibm_is_vpn_gateway.gateway[*].id : []
  description = "The ids of the gateways that were created"
}

output "count" {
  value = var.provision ? var.vpc_subnet_count : 0
  description = "The number of gateways that were created"
}

output "provision" {
  value = true
  description = "The flag indicating that the gateway was provisioned"
}
