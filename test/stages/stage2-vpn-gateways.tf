module "vpn-gateways" {
  source = "./module"

  resource_group_id = module.resource_group.id
  region            = var.region
  ibmcloud_api_key  = var.ibmcloud_api_key
  vpc_name          = module.subnets.vpc_name
  vpc_subnet_count  = module.subnets.count
  vpc_subnets       = module.subnets.subnets
}
