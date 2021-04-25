#!/bin/bash
# auto-test.sh
# script to test auto registration and present summary at end

ver=2.6.16
MODIFIED="April 24, 2021"
SCRIPT_DIR="$(cd $(dirname $0) && pwd)"
TEST_DIR="$SCRIPT_DIR"

# use the CI_SUPPRESS_AUTO_TEST environment variable to skip the auto test
# because it takes a long time.  During test development anyway.
if [ "$CI_SUPPRESS_AUTO_TEST" != "" ]; then
    exit 0
fi


sudo -E "$TEST_DIR"/auto-reg-test.sh  | tee /tmp/auto-reg-result.txt
grep "failed" /tmp/auto-reg-result.txt
if [ $? -eq 0 ]; then
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
grep -n "^DEBUG" /tmp/auto-reg-result.txt >> /tmp/auto-reg-overview.tmp
grep -n "^oemGet" /tmp/auto-reg-result.txt >> /tmp/auto-reg-overview.tmp
grep -n "^#=TEST==" /tmp/auto-reg-result.txt >> /tmp/auto-reg-overview.tmp
echo "============================================================================="
echo "=========  Auto Registration Test Summary ==================================="
sort -g /tmp/auto-reg-overview.tmp | tee /tmp/auto-reg-summary.txt
echo "============================================================================="
echo "============================================================================="
exit 0
