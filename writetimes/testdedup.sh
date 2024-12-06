#!/bin/bash
ITERATIONS=1000
INTERVAL=120
OFFSET=4
INTERITERWAIT=2 # extra wait time between iterations in seconds
LOGPREFIX="logs/"

ITER=0

ddcnt=0
totalpgs=0
declare -a pages
for entry in *.sig; do
	let ddcnt+=1
	datasize=$(stat -c%s "$entry")
	let datasize-=$OFFSET
	pages[$ITER]=$(bc <<< "$datasize/4096")
	if [ $(bc <<< "$datasize%4096") -ne 0 ]; then
		let pages[$ITER]+=1
	fi
	let totalpgs+=${pages[ITER]}
	let ITER+=1
done

totaltime=$(bc -l <<< "$ddcnt*0.25")
if [ $(bc <<< "$totaltime > $INTERVAL") -ne 0 ]; then
	INTERVAL=$totaltime
fi

# Determine sleep time between iterations
# As the testdedup calls themselves might also take some time, we wait an extra $INTERITERWAIT seconds here
sleeptime=$(bc <<< "$INTERITERWAIT+$INTERVAL")
echo "$totaltime $INTERVAL $INTERITERWAIT $sleeptime"

ITER=0
while [ $ITER -lt $ITERATIONS ]; do
	echo "starting new iteration"
	j=0
	for entry in *.sig; do
		itersleeptime=0.25
		echo "Interval: ${INTERVAL}, 1: ${entry}, 2: ${entry::-3}dummydata, l: ${LOGPREFIX}${entry::-3}log, o: ${OFFSET}"
		./testdedup -i $INTERVAL -1 "${entry}" -2 "${entry::-3}dummydata" -l "${LOGPREFIX}${entry::-3}log" -o ${OFFSET} -c&
		echo "${itersleeptime}s"
		sleep ${itersleeptime}s
		let j+=1
	done

	# sleep until all measurements for this iteration have finished

	sleep ${sleeptime}s

	let ITER+=1
done
