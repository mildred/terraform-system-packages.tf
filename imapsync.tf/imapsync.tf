resource "sys_package" "imapsync-dependencies" {
  type = "deb"
  name = each.key
  for_each = toset(["libauthen-ntlm-perl", "libcgi-pm-perl", "libcrypt-openssl-rsa-perl", "libdata-uniqid-perl", "libencode-imaputf7-perl", "libfile-copy-recursive-perl", "libfile-tail-perl", "libio-socket-inet6-perl", "libio-socket-ssl-perl", "libio-tee-perl", "libhtml-parser-perl", "libjson-webtoken-perl", "libmail-imapclient-perl", "libparse-recdescent-perl", "libmodule-scandeps-perl", "libreadonly-perl", "libregexp-common-perl", "libsys-meminfo-perl", "libterm-readkey-perl", "libtest-mockobject-perl", "libtest-pod-perl", "libunicode-string-perl", "liburi-perl", "libwww-perl", "libtest-nowarnings-perl", "libtest-deep-perl", "libtest-warn-perl", "make", "cpanminus"])
}

resource "sys_file" "imapsync" {
  source           = "git::https://github.com/imapsync/imapsync/"
  target_directory = "/opt/imapsync"
  file_permission  = "0755"
}

resource "sys_symlink" "imapsync-symlink" {
  path   = "/usr/local/bin/imapsync"
  source = "/opt/imapsync/imapsync"
}

