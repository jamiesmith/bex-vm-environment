#!/bin/ksh

echo yum clean...
/usr/bin/yum -y clean all

echo fill disk...
cat /dev/zero > /zero.fill 2>/dev/null ; sync ; sleep 1 ; sync ; rm -f /zero.fill

echo shrink...
/usr/bin/vmware-toolbox-cmd disk shrink /
