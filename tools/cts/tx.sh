#!/bin/sh
# Run a command on the phone inside the Termux environment (as the termux app uid).
U=$(adb shell su -c stat -c %u /data/data/com.termux/files/home | tr -d "\r")
adb shell "su $U -c 'export PREFIX=/data/data/com.termux/files/usr HOME=/data/data/com.termux/files/home TMPDIR=/data/data/com.termux/files/usr/tmp; export PATH=\$PREFIX/bin LD_LIBRARY_PATH=\$PREFIX/lib; cd \$HOME; $*'"
