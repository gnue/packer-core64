#!/bin/sh

MNT=${MOUNT_POINT:-"/mnt/sda1"}
DIR="$MNT/home/tc"
OPT="$MNT/opt"

# sshd

# .filetool.lst
cat >> "$OPT/.filetool.lst" << EOF
usr/local/etc/ssh
var/ssh
EOF

# bootlocal.sh
cat >> "$OPT/bootlocal.sh" << EOF

# ssh
if [ ! -f /usr/local/etc/ssh/sshd_config ]; then
  cp /usr/local/etc/ssh/sshd_config_example /usr/local/etc/ssh/sshd_config
fi

/usr/local/etc/init.d/openssh start
EOF
