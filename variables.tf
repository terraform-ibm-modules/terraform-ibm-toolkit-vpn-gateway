#####################################################
# VPN Gateway Configuration
# Copyright 2021 IBM
#####################################################

variable "resource_group_id" {
  type        = string
  description = "The id of the IBM Cloud resource group where the VPC has been provisioned."
}

variable "region" {
  type        = string
  description = "The IBM Cloud region where the cluster will be/has been installed."
}

variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud api token"
}

variable "vpc_name" {
  type        = string
  description = "The name of the vpc instance"
}

variable "label" {
  type        = string
  description = "The label for the server instance"
  default     = "vpn"
}

variable "vpc_subnet_count" {
  type        = number
  description = "Number of vpc subnets"
}

variable "vpc_subnets" {
  type        = list(object({
    label = string
    id    = string
    zone  = string
  }))
  description = "List of subnets with labels"
}

variable "mode" {
  type        = string
  description = "The optional mode of operation for the VPN gateway. Valid values are route or policy"
  default     = null
}

variable "tags" {
  type        = list(string)
  description = "List of tags for the resource"
  default     = []
}

variable "provision" {
  type        = bool
  description = "Flag indicating that the resource should be provisioned. If false the resource will be looked up."
  default     = true
}
