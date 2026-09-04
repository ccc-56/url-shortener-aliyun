resource "alicloud_cs_managed_kubernetes" "this" {
  name                 = "${var.name}-ack"
  cluster_spec         = "ack.pro.small"
  version              = var.kubernetes_version != "" ? var.kubernetes_version : null
  vswitch_ids          = alicloud_vswitch.node[*].id
  pod_vswitch_ids      = alicloud_vswitch.pod[*].id
  service_cidr         = var.service_cidr
  proxy_mode           = "ipvs"
  new_nat_gateway      = false # we created our own above
  slb_internet_enabled = true  # public API server endpoint for kubectl / CI
  security_group_id    = alicloud_security_group.node.id
  deletion_protection  = false
  tags                 = var.tags

  # Terway ENIIP network plugin. Swap to {name="flannel"} + pod_cidr for the overlay network.
  addons {
    name   = "terway-eniip"
    config = jsonencode({ IPVlan = "false", NetworkPolicy = "false" })
  }
  addons {
    name = "csi-plugin"
  }
  addons {
    name = "csi-provisioner"
  }

  timeouts {
    create = "60m"
    delete = "60m"
  }
}

resource "alicloud_cs_kubernetes_node_pool" "default" {
  node_pool_name = "default"
  cluster_id     = alicloud_cs_managed_kubernetes.this.id
  vswitch_ids    = alicloud_vswitch.node[*].id
  instance_types = var.node_instance_types

  system_disk_category = "cloud_essd"
  system_disk_size     = 40
  image_type           = "AliyunLinux3"

  desired_size          = var.node_count
  install_cloud_monitor = true

  security_group_ids = [alicloud_security_group.node.id]

  tags = var.tags
}

# kubeconfig for kubectl / CI. Stored in state -> use a remote, encrypted backend.
data "alicloud_cs_cluster_credential" "this" {
  cluster_id                 = alicloud_cs_managed_kubernetes.this.id
  temporary_duration_minutes = 60 * 24 * 30
  depends_on                 = [alicloud_cs_kubernetes_node_pool.default]
}

resource "local_sensitive_file" "kubeconfig" {
  filename = "${path.module}/kubeconfig"
  content  = data.alicloud_cs_cluster_credential.this.kube_config
}
