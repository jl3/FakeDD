#!/bin/bash
# parameters: statsIntervalSecs numStats benchmarkName

pwd
echo "1: ${1}"
echo "2: ${2}"
echo "3: ${3}"
sar -B ${1} ${2} >> ${3}-sar.txt