#!/bin/sh
# one.sh <case> [extra deqp args]: run one CTS case on the phone; the qpa lands in /tmp/one.qpa.
echo "$1" > /tmp/one.txt && adb push /tmp/one.txt /data/local/tmp/one.txt >/dev/null && adb shell su -c chmod 644 /data/local/tmp/one.txt
shift
"$(dirname "$0")/tx.sh" "cd cts && rm -f one.qpa; LD_LIBRARY_PATH=\$HOME/cts/lib VK_ICD_FILENAMES=\$HOME/panvk-test/d896/icd.json $ENVV ./deqp-vk --deqp-caselist-file=/data/local/tmp/one.txt --deqp-log-filename=one.qpa --deqp-surface-type=pbuffer --deqp-log-images=disable $* >/dev/null 2>&1; echo rc=\$?; cat one.qpa" > /tmp/one.qpa
head -1 /tmp/one.qpa; grep -E "<Text>|<Result|<Number" /tmp/one.qpa | head -${LINES:-40}
