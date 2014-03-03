#!/bin/sh

MNT=${MOUNT_POINT:-"/mnt/sda1"}
DIR="$MNT/home/tc"
OPT="$MNT/opt"

# shutdown
chmod +x "$DIR/.local/sbin/shutdown"

# bootlocal.sh
cat >> "$OPT/bootlocal.sh" << EOF

# shutdown
[ -f /sbin/shutdown ] || ln -s "$DIR/.local/sbin/shutdown" /sbin/shutdown
EOF
