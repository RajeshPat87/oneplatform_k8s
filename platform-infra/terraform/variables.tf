variable "subscription_id" {
  type = string
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "project" {
  type    = string
  default = "oneplatform"
}

variable "aks_node_count" {
  type    = number
  default = 3
}

variable "aks_vm_size" {
  type    = string
  default = "Standard_D4s_v5"
}

variable "aks_k8s_version" {
  type    = string
  default = "1.30.5"
}

variable "vnet_cidr" {
  type    = string
  default = "10.40.0.0/16"
}

variable "aks_subnet_cidr" {
  type    = string
  default = "10.40.0.0/20"
}

variable "pe_subnet_cidr" {
  type    = string
  default = "10.40.16.0/24"
}

variable "tags" {
  type = map(string)
  default = {
    project = "oneplatform"
    owner   = "platform-team"
  }
}
