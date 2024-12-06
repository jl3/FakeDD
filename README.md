# Faking deduplication to prevent timing side-channel attacks on memory deduplication -- Artifact Documentation

This document describes the artifact accompanying the following paper: J. Lindemann, Faking deduplication to prevent timing side-channel attacks on memory deduplication", 40th Annual Computer Security Applications Conference (ACSAC), Waikiki, USA, 2024.

The main artifact is the kernel patch implementing fake deduplication. The remaining files are helper tools used in the evaluation of the paper.

## Kernel (/kernel)

The path /kernel/FakeDD contains the implementation of FakeDD in form of patches for two source files of the Linux 4.10-rc6 kernel used in the evaluation for the paper: First, the file mm/ksm.c, which contains the main logic of Kernel Same-page Merging (KSM). Second, the file mm/Kconfig, which defines the kernel configuration options related to memory management.

The patch to ksm.c modifies the behaviour of KSM so that fake deduplication, as described in the paper, is performed.

Additionally, statistics about fake deduplication can be enabled: Setting CONFIG_KSM_FAKEDEDUP_STATS=y in the kernel configuration enables reporting of fake-deduplicated pages in /sys/kernel/mm/ksm/pages_fakededup. To avoid any potential impact of the statistics code on performance during evaluation, the kernel should be compiled without this option set to run performance evaluations.

To compile a kernel supporting fake deduplication, apply the patches to mm/ksm.c and mm/Kconfig of a 4.10-rc6 kernel. To avoid compatibility issues, it may be helpful to use a Linux distribution designed to use a kernel of a similar version, e.g. Ubuntu 16.04 LTS, as used in the paper.

The sources for kernel 4.10-rc6 can be acquired by running "git clone git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git". Afterwards, run "git checkout v4.10-rc6" in the directory you cloned the kernel sources to. As a base for the configuration, it is recommended to use the default configuration of a similar kernel version of the distribution you are running (e.g. 4.15.0-142-generic in case of Ubuntu 16.04 LTS). This can typically be found in the /boot directory. Copy this to the kernel source directory and run "make olddefconfig" to set any configuration settings not supported by the kernel version of your configuration to the default values. If you do not plan to debug the kernel, you may wish to set CONFIG_DEBUG_INFO=n to save compile time and space. Afterwards, apply any patches you wish to apply. You are now ready to compile the kernel. For Ubuntu 16.04 LTS, this can be done by running "make bindeb-pkg LOCALVERSION=-\<identifier\> -j\<number_of_threads\>". Use different and descriptive LOCALVERSION identifiers (e.g. -fakedd or -vusion) if you wish to run multiple kernel variants on your system, so that you can tell them apart easily in your boot manager. make bindeb-pkg will create a .deb package of the kernel, which can be installed using "dpkg -i".

If you wish to compile a further variant of the kernel without having to clone the kernel sources again, you can reset the cloned git by running "git reset --hard" followed by "git clean -fxd". Note, hoewever, that you will have to copy the configuration file and apply any patches again before compiling.

The VUsion patch was used as provided by the authors and not modified. It is available at <https://github.com/vusec/vusion/blob/master/vusion.patch>.

For the experiments on deduplication performance described in Section 5.2, statistics about copy-on-write/copy-on-access pages with only one virtual page attached are required. VUsion does not report these. Therefore, a patch is provided in the path /kernel/VUsion-fakededupstats. Again, this takes the form of two patches to mm/ksm.c and mm/Kconfig. To apply these, first patch the kernel with the normal VUsion patch, then apply the patches provided. To enable the statistics, set CONFIG_KSM_FAKEDEDUP_STATS=y in the kernel configuration before compiling the kernel.

## Setting up VMs
Both FakeDD and VUsion are based on KSM, the Linux kernel's memory deduplication mechanism. This is typically used to deduplicate pages in virtual machines based on KVM. Therefore, VMs should be created using libvirt and KVM. For this, you can use either the command-line interface virsh or the easier to use graphical frontend virt-manager.

The VMs used for the evaluation were set up by installing the appropriate OS version from an ISO image mounted in the VM and choosing the default installation options. If you wish to compile any applications within the VM, it may be necessary to install the build environment (e.g. install build-essential on Debian-based Linux distributions). Otherwise, only the software required for the experiment needs to be installed.

## Tools for write time measurement (/writetimes)

The path /writetimes contains tools used to obtain write time measurements, as described in Section 5.1. 

loadfile-multi.c contains a program that loads the contents of a file into memory. When compiling the source file, please use gcc -O0 to prevent the compiler from performing optimisations that could impact the measurements. The first parameter of the program must be an offset value in bytes, which defines at which offset the start of the first memory page can be found in the file. This should be higher than 0, but smaller than 4096. For example, an offset of 4 means that the first 4 bytes of the file are ignored. The first page is then loaded from bytes 5 to 4100 in the file, the second file from bytes 4101 to 8196, etc. This avoids caching issues: If memory pages start at a position divisible by 4096 in the file, any copies of the file left in memory by the operating system's file-system cache would be eligible for deduplication with the memory pages created by the program itself, thereby triggering deduplication even for "unique" file contents. Each further parameter specifies a file that should be loaded. After starting, the program will load all files into memory and wait for input. Once a key is pressed, the loaded data is removed from memory and the program quits.

The script loadfiles.sh will load all files *.sig from the current directory into memory using loadfile-multi.c. The offset defaults to 4, but can be changed in the script.

testdedup.c contains a program that loads the contents of a file into memory and then waits for a specified amount of time before overwriting the memory area with the contents of a different file. When compiling the source file, please use gcc -O0 to prevent the compiler from performing optimisations that could impact the measurements. The program takes the following parameters: \<file1\> \<file2\> -i \<interval\> -o \<offset\> -c. file1 is the first file to be loaded, file2 contains the data that the memory region is later overwritten with. interval is the number of seconds to wait between loading the contents of file1 and overwriting them in memory with those of file2. The interval should be set so that the deduplication mechanism is able to identify any duplicate pages in this time, i.e. in most scenarios, it should be set so that all memory areas marked as mergeable can be scanned at least twice within the interval. offset is the offset in bytes at which the start of the first page can be found in the files, similar to the offset in loadfile-multi.c. The c parameter can be set to enable caching: The program will then load the file contents into memory before using them for a timed operation.

The script testdedup.sh can be used to perform a number of measurements. Parameters can be set at the beginning of the script and include the number of iterations to run as well as the interval and offset parameters, which are passed on to testdedup.c. Additionally, a wait time between iterations can be set as well as the prefix for log outputs. The script will look for files *.sig in the current directory. For each iteration, all such files will be loaded once. After observing the wait interval, they are overwritten with a correspondingly named *.dummydata file and the time this takes is measured. The measured time is stored in a log file *.log. The name of the log file is prefixed with the configurable prefix, which allows to store the outputs in a different directory.

To run experiments, files containing random data should be created in pairs: one file as a signature (.sig) and one as dummy data (.dummydata). The file size should be the number of memory pages desired for the experiment multiplied by 4096 plus the offset (e.g. 4). To simulate duplicate pages, the .sig file should be loaded into the memory of a VM using loadfiles.sh. To simulate unique pages, the .sig file should *not* be loaded using loadfiles.sh. In another VM, testdedup.sh should be used to test how long it overtakes the .sig files.

Note that results for this and other experiments will vary depending on the hardware used, i.e. it would *not* be surprising if you received different timings compared to the paper, unless you used the exact same hardware. However, the general results should remain consistent, e.g. on a standard KSM kernel, writing to duplicate memory pages should take longer than to unique pages.

To reproduce the experiments described in Section 5.1, you will need the following VMs with the following software and files on them:

* Victim VM: Debian 10 (1 GiB RAM, 2 cores)
	* loadfile-multi
	* loadfiles.sh
	* dup.sig: file with 50 pages of random data + offset, i.e. 204804 bytes for an offset of 4 bytes
* Victim VM: Debian 11 (1.5 GiB RAM, 2 cores)
	* testdedup.c
	* testdedup.sh
	* dup.sig from victim VM
	* dup.dummydata, nondup.sig, nondup.dummydata: files with random data of the same size as dup.sig. Each file should contain different random data.
	
To speed up the experiment by parallelisation, you may wish to use multiple sets of .sig and .dummydata files.

To perform the experiments, first load the .sig file(s) in the victim VM using loadfiles.sh. Then, use testdedup.sh to perform the timing measurements from the other VM.

## Script for measuring deduplication performance (/dedupperf)

The path /dedupperf contains the script dedupperf.sh, which can be used to capture statistics related to deduplication performance, as described in Section 5.2 of the paper. The script must be run on the host operating system. It assumes that four VMs named "vm1" to "vm4" exist and that there is a snapshot "dedupperf" for each of the VMs. It first reverts the VMs to the snapshot and then resumes then. Immediately afterwards, it activates KSM and starts capturing the statistics every 0.25 seconds.

To reproduce the experiments described in Section 5.2, you will need the following VMs with no additional software and files:

* vm1: Debian 11 (2 GiB RAM, 2 cores)
	* install *with* GUI
* vm2: Debian 11 (2 GiB RAM, 2 cores)
	* install *with* GUI
* vm3: Debian 12 (2 GiB RAM, 2 cores)
	* install *with* GUI
* vm4: FreeBSD 14.0 (2 GiB RAM, 2 cores)

After setting up the VMs, boot them, log in and create a snapshot named "dedupperf". Shut down the VMs, reboot the system with the kernel you wish to test. Ensure that KSM is turned off (echo 0 > /sys/kernel/mm/ksm/run), then start dedupperf.sh on the host OS.

## Application performance: Test suite configurations and scripts for page fault statistics (/appperf)

The path /appperf/test-suites contains the test suite configurations to run the experiments in Phoronix Test Suite. These can be installed by copying them to /var/lib/phoronix-test-suite/test-suites/ within the VM performing the application benchmarks.

To generate the application performance benchmarks (as seen in Table 1), run "phoronix-test-suite strict-run fakedd-eval" and save the results.

To generate the page fault statistics, the "sysstat" package must be installed on the host OS. On Ubuntu, this can be done by running "apt install sysstat". 

To perform the experiment, there are two options: You can either run each of the "idv-" test suites individually using "PTS_CONCURRENT_TEST_RUNS=1 TOTAL_LOOP_TIME=30 phoronix-test-suite stress-run \<test_suite_name\>" and simultaneously monitor the page fault rate on the host using the sar command: "sar -B 60 30".

Alternatively, you can use the scripts provided in /appperf/pagefault-host on the host and /appperf/pagefault-vm in the benchmarking VM. Within the benchmarking VM, runBenchmarks.py will run all individual benchmarks for 30 minutes each. At the same time, recordStats.py will record the page fault statistics (as seen in Table 2) on the host alongside pages_shared, pages_sharing and pages_fakededup (not shown in the paper) in text files within the directory it is being executed from.

To reproduce the experiments described in Section 5.3, you will need the following VMs with the following software and files on them:

* vm5: Debian 10 (1 GiB RAM, 2 cores)
	* loadfile-multi (from /writetimes)
	* loadfiles.sh (from /writetimes)
	* n.sig for 0\<n\<101 with a size of n*4096+4 bytes containing random data.
* vm6: Debian 10 (1 GiB RAM, 2 cores)
	* loadfile-multi
	* loadfiles.sh
	* n.sig for 0\<n\<101, identical to vm5
* vm7: Debian 10 (4 GiB RAM, 2 cores)
	* loadfile-multi
	* loadfiles.sh
	* five files containing non-identical random data, with a size of 512 MiB+4 bytes each
* vm8: Debian 11 (4 GiB RAM, 4 cores)
	* Phoronix Test Suite
	* test suite definitions (/appperf/test-suites)
	* runBenchmarks.py (/appperf/pagefault-vm) for page fault experiment

If performing an experiment with deduplication, ensure by monitoring /sys/kernel/mm/pages_shared and /sys/kernel/mm/pages_sharing that the numbers are higher than 0 and relatively stable.

As described above, to generate the application performance benchmarks (as seen in Table 1), run "phoronix-test-suite strict-run fakedd-eval" in vm8 and save the results.

To generate the page fault statistics, you must instead run two scripts on the host OS and vm8. To ensure that these stay synchronised, they must be started within the same minute. The scripts will display a warning if they are started less than 10 seconds before the turn of a minute and will also display the start time. Ensure that the start time displayed is identical on the host and in vm8. If it is not, abort the experiment and try again.

## Script for measuring CPU consumption of ksmd (/ksmd-cputime)

The path /ksmd-cputime contains the script ksmcpu.sh, which can be used to record the CPU time consumed by the ksmd process, as described in Section 5.4 of the paper. The script must be run on the host operating system. The script first sets the KSM configuration as described in the paper and enables KSM, before starting to record the CPU time consumed by the ksmd process in 30-second intervals.

To reproduce the experiments described in Section 5.4, you will need the same VMs as for the application performance experiments.
