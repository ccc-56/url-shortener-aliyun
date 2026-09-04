data "alicloud_zones" "ack" {
  available_resource_creation = "VSwitch"
}

locals {
  zones = slice(data.alicloud_zones.ack.zones[*].id, 0, length(var.vswitch_cidrs))
}

resource "alicloud_vpc" "this" {
  vpc_name   = "${var.name}-vpc"
  cidr_block = var.vpc_cidr
  tags       = var.tags
}

# node / control-plane ENI vSwitches
resource "alicloud_vswitch" "node" {
  count        = length(var.vswitch_cidrs)
  vswitch_name = "${var.name}-node-${count.index}"
  vpc_id       = alicloud_vpc.this.id
  cidr_block   = var.vswitch_cidrs[count.index]
  zone_id      = local.zones[count.index]
  tags         = var.tags
}

# pod vSwitches for Terway (pod IPs are real VPC IPs, routable from ECS/RDS/Redis)
resource "alicloud_vswitch" "pod" {
  count        = length(var.pod_vswitch_cidrs)
  vswitch_name = "${var.name}-pod-${count.index}"
  vpc_id       = alicloud_vpc.this.id
  cidr_block   = var.pod_vswitch_cidrs[count.index]
  zone_id      = local.zones[count.index]
  tags         = var.tags
}

# NAT gateway so nodes can pull public images (redis:7-alpine) and reach the internet.
resource "alicloud_nat_gateway" "this" {
  vpc_id           = alicloud_vpc.this.id
  nat_gateway_name = "${var.name}-nat"
  nat_type         = "Enhanced"
  network_type     = "internet"
  payment_type     = "PayAsYouGo"
  vswitch_id       = alicloud_vswitch.node[0].id
  tags             = var.tags
}

resource "alicloud_eip_address" "nat" {
  address_name         = "${var.name}-nat-eip"
  bandwidth            = "10"
  internet_charge_type = "PayByTraffic"
  payment_type         = "PayAsYouGo"
  tags                 = var.tags
}

resource "alicloud_eip_association" "nat" {
  allocation_id = alicloud_eip_address.nat.id
  instance_id   = alicloud_nat_gateway.this.id
  instance_type = "Nat"
}

resource "alicloud_snat_entry" "node" {
  count             = length(alicloud_vswitch.node)
  snat_table_id     = alicloud_nat_gateway.this.snat_table_ids
  source_vswitch_id = alicloud_vswitch.node[count.index].id
  snat_ip           = alicloud_eip_address.nat.ip_address
}

resource "alicloud_snat_entry" "pod" {
  count             = length(alicloud_vswitch.pod)
  snat_table_id     = alicloud_nat_gateway.this.snat_table_ids
  source_vswitch_id = alicloud_vswitch.pod[count.index].id
  snat_ip           = alicloud_eip_address.nat.ip_address
}

resource "alicloud_security_group" "node" {
  security_group_name = "${var.name}-node-sg"
  vpc_id              = alicloud_vpc.this.id
  tags                = var.tags
}

# intra-VPC traffic (node<->node, node<->pod)
resource "alicloud_security_group_rule" "vpc_in" {
  type              = "ingress"
  ip_protocol       = "all"
  port_range        = "-1/-1"
  cidr_ip           = var.vpc_cidr
  security_group_id = alicloud_security_group.node.id
}

# CLB health checks / NodePort traffic come from the 100.64.0.0/10 CLB range
resource "alicloud_security_group_rule" "clb_in" {
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "30000/32767"
  cidr_ip           = "100.64.0.0/10"
  security_group_id = alicloud_security_group.node.id
}
