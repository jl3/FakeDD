#!/usr/bin/env python3

import datetime
import os
import time

benchmarkRunMins = 30
benchmarkPauseMins = 3
statIntervalSecs = 60

benchmarks = ["idv-01-7zip", "idv-02-dbench", "idv-03-lame", "idv-04-openssl", "idv-05-perfbench-epoll",
              "idv-06-perfbench-futexhash", "idv-07-perfbench-memcpy", "idv-08-perfbench-memset",
              "idv-09-perfbench-schedpipe", "idv-10-perfbench-futexlockpi", "idv-11-perfbench-syscall",
              "idv-12-pmbench-rw", "idv-13-pmbench-r", "idv-14-pmbench-w", "idv-15-pgbench", "idv-16-sqlite",
              "idv-17-x264", "idv-18-memcached", "idv-19-apache"]

def sleepUntil(hour, minute, second):
    currentTime = datetime.datetime.now()
    currentHour = currentTime.hour
    if currentHour > hour:
        hour = hour + 24
    wait = second - currentTime.second + 60 * (minute - currentTime.minute) + 3600 * (hour - currentHour)
    time.sleep(wait)

def main():
    currentTime = datetime.datetime.now()

    starthour = currentTime.hour
    startminute = currentTime.minute
    startsecond = currentTime.second

    if startsecond > 50:
        print("WARNING: Script was started less than 10 seconds before full minute.")

    startminute = startminute + 2
    startsecond = 0

    if startminute >= 60:
        starthour = starthour + 1
        startminute = startminute - 60

        if starthour >= 24:
            starthour = starthour - 24

    print("Start time: " + str(starthour) + ":" + str(startminute) + ":" + str(startsecond))
    sleepUntil(starthour, startminute, startsecond)

    print(datetime.datetime.now())

    for benchmark in benchmarks:
        os.system("PTS_CONCURRENT_TEST_RUNS=1 TOTAL_LOOP_TIME=30 phoronix-test-suite stress-run " + benchmark)

        startminute = startminute + benchmarkRunMins + benchmarkPauseMins
        while startminute >= 60:
            starthour = starthour + 1
            startminute = startminute - 60
        if starthour >= 24:
            starthour = starthour - 24

        sleepUntil(starthour, startminute, startsecond)

if __name__=="__main__":
    main()
