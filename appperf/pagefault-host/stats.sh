#!/bin/bash

date >> ${1}-date.txt
cat /sys/kernel/mm/ksm/pages_shared >> ${1}-pagesshared.txt
cat /sys/kernel/mm/ksm/pages_sharing >> ${1}-pagessharing.txt
cat /sys/kernel/mm/ksm/pages_fakededup >> ${1}-pagesunshared.txt
ps -C ksmd -o cputime | tail -1 >> ${1}-cputime.txt
