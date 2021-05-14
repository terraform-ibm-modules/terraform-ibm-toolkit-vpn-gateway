#####################################################
# VPN Gateway Configuration
# Copyright 2021 IBM
#####################################################

locals {
  name = replace("${var.vpc_name}-${var.label}", "/[^a-zA-Z0-9_\\-\\.]/", "")
  subnet_ids  = var.vpc_subnets[*].id
}

resource ibm_is_vpn_gateway gateway {
  count = var.provision ? var.vpc_subnet_count : 0

  name           = "${local.name}${format("%02s", count.index + 1)}"
  resource_group = var.resource_group_id
  subnet         = local.subnet_ids[count.index]
  tags           = (var.tags != null ? var.tags : [])
  mode           = var.mode
}
