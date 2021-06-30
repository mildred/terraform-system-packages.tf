# https://wiki.debian.org/UnattendedUpgrades

resource "sys_package" "unattended-upgrades" {
  type = "deb"
  name = "unattended-upgrades"
}

resource "sys_package" "apt-listchanges" {
  type = "deb"
  name = "apt-listchanges"
}

resource "sys_file" "exim_conf" {
  filename = "/etc/apt/apt.conf.d/02periodic"
  content  = <<CONF
// Control parameters for cron jobs by /etc/cron.daily/apt-compat //


// Enable the update/upgrade script (0=disable)
APT::Periodic::Enable "1";


// Do "apt-get update" automatically every n-days (0=disable)
APT::Periodic::Update-Package-Lists "1";


// Do "apt-get upgrade --download-only" every n-days (0=disable)
APT::Periodic::Download-Upgradeable-Packages "1";


// Run the "unattended-upgrade" security upgrade script
// every n-days (0=disabled)
// Requires the package "unattended-upgrades" and will write
// a log in /var/log/unattended-upgrades
APT::Periodic::Unattended-Upgrade "1";


// Do "apt-get autoclean" every n-days (0=disable)
APT::Periodic::AutocleanInterval "21";


// Send report mail to root
//     0:  no report             (or null string)
//     1:  progress report       (actually any string)
//     2:  + command outputs     (remove -qq, remove 2>/dev/null, add -d)
//     3:  + trace on
APT::Periodic::Verbose "2";

CONF
}
