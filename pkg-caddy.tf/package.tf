variable "layer4" {
  default = false
}

variable "xcaddy_version" {
  default = "0.1.9"
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

resource "sys_file" "xcaddy_ar" {
  count            = local.with_l4 ? 1 : 0
  target_directory = "/root/xcaddy"
  source           = "https://github.com/caddyserver/xcaddy/releases/download/v${var.xcaddy_version}/xcaddy_${var.xcaddy_version}_linux_amd64.tar.gz"
  force_overwrite  = true
}

resource "sys_file" "xcaddy" {
  count            = local.with_l4 ? 1 : 0
  filename         = "/usr/local/bin/xcaddy"
  source           = "${sys_file.xcaddy_ar[count.index].target_directory}/xcaddy"
  file_permission  = 0755
}

resource "sys_package" "golang" {
  count          = local.with_l4 ? 1 : 0
  type           = "deb"
  name           = "golang"
  target_release = "buster-backports"
}

resource "sys_shell_script" "caddy_l4" {
  count             = local.with_l4 ? 1 : 0
  depends_on        = [ sys_package.golang ]
  working_directory = "/root"
  filename          = "/usr/local/bin/caddy"

  //create = "${sys_file.xcaddy[count.index].filename} build --with github.com/mholt/caddy-l4 --output /usr/local/bin/caddy"
  create = "${sys_file.xcaddy[count.index].filename} build --with github.com/mholt/caddy-l4@master --output /usr/local/bin/caddy"
}

#
# Outputs
#

output "bin" {
  value = local.bin
}



