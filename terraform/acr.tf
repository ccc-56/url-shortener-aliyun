# Container Registry (personal edition). Images:
#   registry.<region>.aliyuncs.com/<acr_namespace>/url-shortener-app
#   registry.<region>.aliyuncs.com/<acr_namespace>/url-shortener-nginx
resource "alicloud_cr_namespace" "this" {
  name               = var.acr_namespace
  auto_create        = false
  default_visibility = "PRIVATE"
}

resource "alicloud_cr_repo" "app" {
  namespace = alicloud_cr_namespace.this.name
  name      = "url-shortener-app"
  summary   = "URL shortener Node.js API"
  repo_type = "PRIVATE"
}

resource "alicloud_cr_repo" "nginx" {
  namespace = alicloud_cr_namespace.this.name
  name      = "url-shortener-nginx"
  summary   = "URL shortener static frontend + reverse proxy"
  repo_type = "PRIVATE"
}

# ACK nodes pull from the same-region ACR over the VPC endpoint without credentials
# only for public repos; for private repos create an imagePullSecret (see README).
