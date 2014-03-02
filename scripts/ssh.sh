#!/bin/sh

MNT="/mnt/sda"
DIR="$MNT/home/tc"
OPT="$MNT/opt"

# ssh
mkdir -p "$DIR/.ssh"
chmod 700 "$DIR/.ssh"

cat "$DIR/.local/vagrant_keys" >> "$DIR/.ssh/authorized_keys"
chmod 0600 "$DIR/.ssh/authorized_keys"

chown -R tc:staff "$DIR/.ssh"

# .filetool.lst
cat >> "$OPT/.filetool.lst" << EOF
usr/local/etc/ssh
EOF

# bootlocal.sh
cat >> "$OPT/bootlocal.sh" << EOF

# ssh
if [ ! -f /usr/local/etc/ssh/sshd_config ]; then
  cp /usr/local/etc/ssh/sshd_config_example /usr/local/etc/ssh/sshd_config
fi

/usr/local/etc/init.d/openssh start
EOF
