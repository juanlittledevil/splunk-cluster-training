#!/bin/bash
# Template for bootstrapping.
# This is automatically placed in scenarioX/files/01-helper.sh
# The idea is that bootrapping will just execute any file called *-helper.sh
# living inside the files folder.

# Global Variables
# ================

# nfs mount back to your box.
base="/vagrant"

host_name=$1

# Splunk RPM get latest.
#splunk_rpm="${base}/files/rpm/splunk-6.5.1-f74036626f0c-linux-2.6-x86_64.rpm"
# Instal the newest file based on timestat. Best if you only put one file in there....
splunk_rpm="$(ls -tr ${base}/files/rpm/splunk*.rpm | tail -1)"

splunk_home="/opt/splunk"

splunk_executable="${splunk_home}/bin/splunk"


# Functions
# =========

check_return() {
  return=$1
  if [ $return -eq 0 ]; then
    echo "[OK]"
  else
    echo "Whoops: something went wrong with that last step"
    exit 1
  fi
}

# Main
# ====
# disable SELENUX.
sed -i 's/=enforcing/=disabled/g' /etc/sysconfig/selinux

# Install NGINX
yum -y update
yum clean all

yum -y install epel-release
yum -y install nginx

# Configure nginx.
# ==================

# Move in all nginx configs into place.
pwd=$(pwd)
cd ${base}/files/$host_name
files=$(find etc -type f -print)
cd $pwd

for file in $files
do
  cp ${base}/files/$host_name/$file /$file
done

# inline mods.
#sed -i "s/^module = manage_bind/module = manage_dnsmasq/g" /etc/cobbler/modules.conf

# Enable services.
# ================
setsebool -P httpd_can_network_connect 1

service nginx start

exit 0
