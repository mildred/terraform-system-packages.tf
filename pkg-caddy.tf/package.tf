variable "layer4" {
  default = false
}

locals {
  with_l4 = var.layer4 != false
  bin     = local.with_l4 ? "/usr/local/bin/caddy" : "/usr/bin/caddy"
}

#
# Standard Caddy
#

resource "sys_file" "apt_list" {
  filename = "/etc/apt/sources.list.d/caddy-fury.list"
  content  = <<APT_LIST
deb [trusted=yes] https://apt.fury.io/caddy/ /
APT_LIST
}

resource "sys_package" "caddy" {
  type       = "deb"
  name       = "caddy"
  depends_on = [ sys_file.apt_list ]
}

#
# xcaddy
#

resource "sys_file" "caddy_l4" {
  count    = local.with_l4 ? 1 : 0
  filename = local.bin
  source   = "https://caddyserver.com/api/download?os=linux&arch=amd64&p=github.com%2Fmholt%2Fcaddy-l4"

  file_permission  = 0755
}

#
# Outputs
#

output "bin" {
  value = local.bin
}

output "done" {
  value = [sys_file.caddy_l4.*.id, sys_package.caddy.*.id]
}


