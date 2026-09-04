terraform {
  required_version = ">= 1.5"

  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = ">= 1.240, < 1.276" # personal-edition ACR resources deprecated in 1.276
    }
  }

  # Recommended: keep state in OSS.
  # backend "oss" {
  #   bucket = "my-tfstate-bucket"
  #   prefix = "url-shortener/ack"
  #   region = "cn-hangzhou"
  # }
}

# Credentials come from ALICLOUD_ACCESS_KEY / ALICLOUD_SECRET_KEY env vars
# (or ALICLOUD_PROFILE) - never hard-code them here.
provider "alicloud" {
  region = var.region
}
