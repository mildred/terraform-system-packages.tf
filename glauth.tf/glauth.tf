variable "glauth_version" {
  default = "1.1.2"
}

variable "arch_suffix" {
  default = "64"
}

locals {
  unit_name = "glauth"
}

resource "sys_file" "glauth" {
  filename        = "/usr/local/bin/glauth"
  #source          = "https://github.com/glauth/glauth/releases/download/v${var.glauth_version}/glauth${var.arch_suffix}"
  source          = "https://github.com/mildred/glauth/releases/download/latest-master/glauth${var.arch_suffix}"
  file_permission = 0755
}

resource "sys_file" "conf" {
  filename = "/etc/glauth.conf"
  content  = file("${path.module}/glauth.conf")
}

resource "sys_file" "glauth_socket_service" {
  filename = "/etc/systemd/system/${local.unit_name}-socket.service"
  content  = <<CONF
[Unit]
Requires=addr@${local.unit_name}.service
After=addr@${local.unit_name}.service

[Service]
Type=simple
EnvironmentFile=/run/addr/${local.unit_name}.env
RemainAfterExit=true
ExecStartPre=-/usr/bin/systemctl stop ${local.unit_name}.socket
ExecStart=/usr/bin/systemd-run \
  --unit=${local.unit_name}.socket \
  --property=Requires=${local.unit_name}-socket.service \
  --property=After=${local.unit_name}-socket.service \
  --socket-property=ListenStream=$${HOSTADDR4}:3893
ExecStop=-/usr/bin/systemctl stop ${local.unit_name}.socket

[Install]
WantedBy=network-pre.target

CONF
}

resource "sys_file" "glauth_service" {
  filename = "/etc/systemd/system/${local.unit_name}.service"
  content  = <<CONF
[Unit]
After=network.target
Requires=${local.unit_name}-socket.service ${local.unit_name}.socket
After=${local.unit_name}-socket.service ${local.unit_name}.socket

[Service]
EnvironmentFile=/run/addr/${local.unit_name}.env
ExecStart=/usr/local/bin/force-bind \
  -m /0:3893=sd=0 \
  /usr/local/bin/glauth \
    -c /etc/glauth.conf

CONF
}

resource "sys_systemd_unit" "service" {
  name = "${local.unit_name}.service"
  enable = false
  start  = false
  restart_on = {
    service_unit = sys_file.glauth_service.id
  }
}

resource "sys_systemd_unit" "socket" {
  name = "${local.unit_name}-socket.service"
  enable = true
  start  = true
  restart_on = {
    service_unit = sys_file.glauth_service.id
    socket_unit  = sys_file.glauth_socket_service.id
  }
  depends_on = [ sys_systemd_unit.service ]
}
