#!/bin/bash

virsh snapshot-revert vm1 dedupperf --paused
virsh snapshot-revert vm2 dedupperf --paused
virsh snapshot-revert vm3 dedupperf --paused
virsh snapshot-revert vm4 dedupperf --paused

virsh resume vm1
virsh resume vm2
virsh resume vm3
virsh resume vm4

date >> times.txt
cat /sys/kernel/mm/ksm/pages_shared >> pagesshared.txt
cat /sys/kernel/mm/ksm/pages_sharing >> pagessharing.txt
cat /sys/kernel/mm/ksm/pages_fakededup >> pagesfakededup.txt

echo 100 > /sys/kernel/mm/ksm/pages_to_scan
echo 20 > /sys/kernel/mm/ksm/sleep_millisecs
echo 1 > /sys/kernel/mm/ksm/run

while true
do
	date >> times.txt
	cat /sys/kernel/mm/ksm/pages_shared >> pagesshared.txt
	cat /sys/kernel/mm/ksm/pages_sharing >> pagessharing.txt
	cat /sys/kernel/mm/ksm/pages_fakededup >> pagesfakededup.txt
	sleep 0.25s
done
