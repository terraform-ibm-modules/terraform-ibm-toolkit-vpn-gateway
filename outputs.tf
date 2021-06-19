#####################################################
# VPN Gateway Configuration
# Copyright 2021 IBM
#####################################################

output "ids" {
  value = var.provision ? local.output[*].id : []
  description = "The ids of the gateways that were created"
}

output "crns" {
  value = var.provision ? local.output[*].crn : []
  description = "The crns of the gateways that were created"
}

output "count" {
  value = var.provision ? var.vpc_subnet_count : 0
  description = "The number of gateways that were created"
}

output "provision" {
  value = true
  description = "The flag indicating that the gateway was provisioned"
}
