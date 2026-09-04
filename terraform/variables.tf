variable "region" {
  description = "Alibaba Cloud region"
  type        = string
  default     = "cn-hangzhou"
}

variable "name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "url-shortener"
}

variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

# Two vSwitches in different zones so nodes / CLB are zone-redundant.
variable "vswitch_cidrs" {
  type    = list(string)
  default = ["10.10.1.0/24", "10.10.2.0/24"]
}

# Terway ENIIP mode: pods get IPs from dedicated pod vSwitches in the same zones.
variable "pod_vswitch_cidrs" {
  type    = list(string)
  default = ["10.10.16.0/20", "10.10.32.0/20"]
}

variable "service_cidr" {
  description = "ClusterIP range (must not overlap the VPC)"
  type        = string
  default     = "172.21.0.0/20"
}

variable "kubernetes_version" {
  description = "ACK managed cluster version; leave empty for the latest supported"
  type        = string
  default     = ""
}

variable "node_instance_types" {
  description = "ECS types for the worker node pool (first available is used per zone)"
  type        = list(string)
  default     = ["ecs.c6.large", "ecs.c7.large", "ecs.g6.large"]
}

variable "node_count" {
  type    = number
  default = 2
}

variable "acr_namespace" {
  description = "Container Registry (personal edition) namespace; must be globally unique"
  type        = string
}

variable "tags" {
  type = map(string)
  default = {
    project = "url-shortener"
    managed = "terraform"
  }
}
