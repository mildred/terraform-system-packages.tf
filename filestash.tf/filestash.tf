variable "dav_addr" {
}
variable "sd_prefix" {
  default = ""
}

locals {
  unit_name = "${var.sd_prefix}filestash"
}

resource "sys_file" "service" {
  filename = "/etc/systemd/system/${local.unit_name}.service"
  content  = <<CONF
[Unit]
Requires=docker.socket
After=network.target docker.socket
Requires=addr@${local.unit_name}.service addr@${var.dav_addr}.service
After=addr@${local.unit_name}.service addr@${var.dav_addr}.service

[Service]
Restart=always
TimeoutStartSec=600
EnvironmentFile=/run/addr/${var.dav_addr}.env
EnvironmentFile=/run/addr/${local.unit_name}.env
ExecStartPre=/usr/bin/mkdir -p /var/lib/${local.unit_name}
ExecStartPre=-/usr/bin/docker pull machines/filestash:latest
ExecStartPre=-/usr/bin/docker rm -f ${local.unit_name}
ExecStartPre=/usr/bin/docker run -d \
  --rm \
  --name ${local.unit_name} \
  --add-host dav:$${HOST_${replace(var.dav_addr, "-", "_")}6} \
  -e APPLICATION_URL= \
  -p $${HOSTADDR4}:8080:8334 \
  machines/filestash:latest
ExecStart=/usr/bin/docker attach ${local.unit_name}
ExecStop=/usr/bin/docker stop ${local.unit_name}

[Install]
WantedBy=multi-user.target
CONF
}

resource "sys_systemd_unit" "service" {
  count = 0
  name = "${local.unit_name}.service"
  enable = true
  start  = true
  restart_on = {
    service_unit = sys_file.service.id
  }
}

output "sd_addr" {
  value = local.unit_name
}

