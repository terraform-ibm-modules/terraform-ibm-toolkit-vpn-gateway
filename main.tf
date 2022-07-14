#####################################################
# VPN Gateway Configuration
# Copyright 2021 IBM
#####################################################

locals {
  tmp_dir = "${path.cwd}/.tmp/vpn-gateway"
  name = replace("${var.vpc_name}-${var.label}", "/[^a-zA-Z0-9_\\-\\.]/", "")
  subnet_ids  = var.vpc_subnets[*].id
  output = jsondecode(data.external.vpn_gateways.result.output)
}

module setup_clis {
  source = "cloud-native-toolkit/clis/util"

  clis = ["jq"]
}

resource null_resource vpn_gateways {
  count = var.provision ? 1 : 0

  triggers = {
    region = var.region
    resource_group = var.resource_group_id
    subnet_ids = join(",", local.subnet_ids)
    ibmcloud_api_key = var.ibmcloud_api_key
    bin_dir = module.setup_clis.bin_dir
    tmp_dir = local.tmp_dir
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/create-gateways.sh '${self.triggers.region}' '${self.triggers.resource_group}' '${local.name}' '${self.triggers.subnet_ids}'"

    environment = {
      IBMCLOUD_API_KEY = self.triggers.ibmcloud_api_key
      BIN_DIR = self.triggers.bin_dir
      TMP_DIR = self.triggers.tmp_dir
    }
  }

  provisioner "local-exec" {
    when = destroy

    command = "${path.module}/scripts/delete-gateways.sh '${self.triggers.region}' '${self.triggers.resource_group}' '${self.triggers.subnet_ids}'"

    environment = {
      IBMCLOUD_API_KEY = self.triggers.ibmcloud_api_key
      BIN_DIR = self.triggers.bin_dir
      TMP_DIR = self.triggers.tmp_dir
    }
  }
}

data external vpn_gateways {
  program = ["bash", "${path.module}/scripts/list-gateways.sh"]

  query = {
    bin_dir = module.setup_clis.bin_dir
    region = var.region
    resource_group = var.resource_group_id
    subnet_ids = jsonencode(local.subnet_ids)
    ibmcloud_api_key = var.ibmcloud_api_key
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
