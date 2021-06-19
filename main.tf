#####################################################
# VPN Gateway Configuration
# Copyright 2021 IBM
#####################################################

locals {
  name = replace("${var.vpc_name}-${var.label}", "/[^a-zA-Z0-9_\\-\\.]/", "")
  subnet_ids  = var.vpc_subnets[*].id
}

resource null_resource create_gateway {
  provisioner "local-exec" {
    command = "${path.module}/scripts/create-gateway.sh '${var.region}' '${local.name}' '${join(",", local.subnet_ids)}'"

    environment = {
      IBMCLOUD_API_KEY = var.ibmcloud_api_key
    }
  }
}

//resource ibm_is_vpn_gateway gateway {
//  count = var.provision ? var.vpc_subnet_count : 0
//
//  name           = "${local.name}${format("%02s", count.index + 1)}"
//  resource_group = var.resource_group_id
//  subnet         = local.subnet_ids[count.index]
//  tags           = concat((var.tags != null ? var.tags : []), [count.index == 0 ? "gateway" : (ibm_is_vpn_gateway.gateway[count.index - 1].id != "" ? "gateway" : "gateway")])
//  mode           = var.mode
//}
