variable "layer4" {
  default = false
}

data "sys_shell_script" "uname-m" {
  read = "uname -m | xargs printf %s"
}

locals {
  arch = lookup({
    "x86_64"  = "amd64",
    "aarch64" = "arm64"
  }, data.sys_shell_script.uname-m.content, data.sys_shell_script.uname-m.content)
}

locals {
  with_l4 = var.layer4 != false
  bin     = local.with_l4 ? "/usr/local/bin/caddy" : "/usr/bin/caddy"
  dl_url  = "https://caddyserver.com/api/download?os=linux&arch=${local.arch}&p=github.com%2Fmholt%2Fcaddy-l4&p=github.com%2Fgreenpau%2Fcaddy-security"
  manual_caddy_update = local.with_l4 && false # Included in Caddy
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
  source   = local.dl_url

  file_permission  = 0755
}

resource "sys_file" "update_caddy_env" {
  count    = local.manual_caddy_update ? 1 : 0
  filename = "/etc/update-caddy.env"
  content  = <<CONF
URL=${local.dl_url}
CONF
}
resource "sys_file" "update_caddy_service" {
  count    = local.manual_caddy_update ? 1 : 0
  filename = "/etc/systemd/system/update-caddy.service"
  content  = <<CONF
[Unit]
Description=Update Caddy

[Service]
EnvironmentFile=${sys_file.update_caddy_env[count.index].filename}
ExecStart=/bin/sh -xec ' \
  /usr/bin/curl -s -o ${local.bin}.new "$$URL"; \
  chmod +x ${local.bin}.new; \
  mv ${local.bin}.new ${local.bin}; \
  '

CONF
}

resource "sys_file" "update_caddy_timer" {
  count    = local.manual_caddy_update ? 1 : 0
  filename = "/etc/systemd/system/update-caddy.timer"
  content  = <<CONF
[Unit]
Description=Update Caddy

[Timer]
OnCalendar=weekly

[Install]
WantedBy=multi-user.target
CONF
}

resource "sys_systemd_unit" "update_caddy_timer" {
  count  = local.manual_caddy_update ? 1 : 0
  name   = "update-caddy.timer"
  enable = true
  start  = true
  restart_on = {
    service_unit = sys_file.update_caddy_service[count.index].id
    service_unit = sys_file.update_caddy_timer[count.index].id
  }
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


