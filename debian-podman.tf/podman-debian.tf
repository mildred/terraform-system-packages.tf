resource "sys_file" "apt_list" {
  filename = "/etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list"
  content  = <<APT_LIST
deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/Debian_10/ /
APT_LIST
}

resource "sys_shell_script" "apt_key" {
  working_directory = "/tmp"
  create = "curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/Debian_10/Release.key | sudo apt-key add -"
  read = "curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/Debian_10/Release.key | md5sum"
  delete = "true"
}

resource "sys_package" "podman" {
  type = "deb"
  name = "podman"
  depends_on = [ sys_file.apt_list, sys_shell_script.apt_key ]
}

