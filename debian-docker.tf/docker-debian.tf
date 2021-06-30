variable "fixed_cidr_v6" {
  default = ""
}

resource "random_integer" "sd_ula_netnum_1" {
  min = 0
  max = 1048575 # 2^20 - 1
}

resource "random_integer" "sd_ula_netnum_2" {
  min = 0
  max = 1048575 # 2^20 - 1
}

locals {
  fixed_cidr_v6 = (var.fixed_cidr_v6 != "") ? var.fixed_cidr_v6 : cidrsubnet(cidrsubnet("fd00::/8", 20, random_integer.sd_ula_netnum_1.result), 20, random_integer.sd_ula_netnum_2.result)
}

resource "sys_file" "docker_daemon_json" {
  filename = "/etc/docker/daemon.json"
  content = jsonencode({
    ipv6 = true
    fixed-cidr-v6 = local.fixed_cidr_v6
  })
}

resource "sys_package" "docker" {
  type = "deb"
  name = "docker.io"
}

output "default_ipv6_cidr" {
  value = local.fixed_cidr_v6
}
