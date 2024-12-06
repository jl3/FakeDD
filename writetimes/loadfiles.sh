#!/bin/bash
OFFSET=4

filestr=""

for entry in *.sig; do
	filestr="${filestr} ${entry}"
done

./loadfile-multi ${OFFSET}${filestr}
