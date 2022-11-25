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

resource "sys_file" "docker-system-prune_timer" {
  filename = "/etc/systemd/system/docker-system-prune.timer"
  content  = <<CONF
[Timer]
OnCalendar=weekly

[Install]
WantedBy=multi-user.target
CONF
}

resource "sys_file" "docker-system-prune_service" {
  filename = "/etc/systemd/system/docker-system-prune.service"
  content  = <<CONF
[Service]
ExecStart=docker system prune -f

CONF
}

resource "sys_systemd_unit" "docker-system-prune" {
  depends_on = [
    sys_file.docker-system-prune_service,
    sys_file.docker-system-prune_timer
  ]
  name = "docker-system-prune.timer"
  enable = true
  start = true
}

output "default_ipv6_cidr" {
  value = local.fixed_cidr_v6
}
