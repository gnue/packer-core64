#!/bin/sh

MNT="/mnt/sda"
DIR="$MNT/home/tc"
OPT="$MNT/opt"

# shutdown
chmod +x "$DIR/.local/sbin/shutdown"

# bootlocal.sh
cat >> "$OPT/bootlocal.sh" << EOF

# shutdown
[ -f /sbin/shutdown ] || ln -s "$DIR/.local/sbin/shutdown" /sbin/shutdown
EOF
