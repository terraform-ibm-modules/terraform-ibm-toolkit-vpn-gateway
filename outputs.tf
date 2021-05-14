#####################################################
# VPN Gateway Configuration
# Copyright 2021 IBM
#####################################################

output "ids" {
  value = local.gateway_ids
  description = "The ids of the gateways that were created"
}

output "provision" {
  value = var.provision
  description = "The flag indicating that the gateway was provisioned"
}
