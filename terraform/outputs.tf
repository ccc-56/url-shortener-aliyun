output "cluster_id" {
  value = alicloud_cs_managed_kubernetes.this.id
}

output "kubeconfig_path" {
  value = local_sensitive_file.kubeconfig.filename
}

output "acr_registry" {
  value = "registry.${var.region}.aliyuncs.com/${alicloud_cr_namespace.this.name}"
}

output "acr_registry_vpc" {
  description = "Use this pull address from inside the cluster (no public egress needed)"
  value       = "registry-vpc.${var.region}.aliyuncs.com/${alicloud_cr_namespace.this.name}"
}

output "nat_eip" {
  value = alicloud_eip_address.nat.ip_address
}
