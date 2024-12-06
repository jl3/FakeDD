#!/bin/bash

echo 500 > /sys/kernel/mm/ksm/pages_to_scan
echo 10 > /sys/kernel/mm/ksm/sleep_millisecs
echo 1 > /sys/kernel/mm/ksm/run

while true
do
	date >> times.txt
	ps -C ksmd -o cputime | tail -1 >> cputime.txt
	sleep 30s
done
