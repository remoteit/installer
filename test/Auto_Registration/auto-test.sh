#!/bin/bash
# auto-test.sh
# script to test auto registration and present summary at end

ver=2.1.14
MODIFIED="June 21, 2020"
SCRIPT_DIR="$(cd $(dirname $0) && pwd)"
TEST_DIR="$SCRIPT_DIR"

sudo -E "$TEST_DIR"/auto-reg-test.sh  | tee /tmp/auto-reg-result.txt
if [ $? -ne 0 ]; then
    echo "Auto Registration failure!"
    exit 1
fi
grep -n "^Test step" /tmp/auto-reg-result.txt > /tmp/auto-reg-overview.tmp
grep -n "^Clone" /tmp/auto-reg-result.txt >> /tmp/auto-reg-overview.tmp
grep -n -A 2 "^Available UID" /tmp/auto-reg-result.txt >> /tmp/auto-reg-overview.tmp
grep -n "^dprovision" /tmp/auto-reg-result.txt >> /tmp/auto-reg-overview.tmp
grep -n "^bprovision" /tmp/auto-reg-result.txt >> /tmp/auto-reg-overview.tmp
grep -n "^Hardware ID" /tmp/auto-reg-result.txt >> /tmp/auto-reg-overview.tmp
grep -n "^hardware_id.txt" /tmp/auto-reg-result.txt >> /tmp/auto-reg-overview.tmp
grep -n "^System ID" /tmp/auto-reg-result.txt >> /tmp/auto-reg-overview.tmp
grep -n "^Reset" /tmp/auto-reg-result.txt >> /tmp/auto-reg-overview.tmp
grep -n "^oemGet" /tmp/auto-reg-result.txt >> /tmp/auto-reg-overview.tmp
grep -n "^#=TEST==" /tmp/auto-reg-result.txt >> /tmp/auto-reg-overview.tmp
echo "============================================================================="
echo "=========  Auto Registration Test Summary ==================================="
sort -g /tmp/auto-reg-overview.tmp | tee /tmp/auto-reg-summary.txt
echo "============================================================================="
echo "============================================================================="
