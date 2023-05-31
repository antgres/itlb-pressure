ITLB Pressure scripts
=====================

This repo contains the test scripts for the master's thesis titled "Analysis
of the reduction of iTLB cache pressure through code collocation based on the
linux kernel." These scripts are tested on the Intel Core i3-6100U CPU with
Skylake microarchitecture. If you are using a different processor model,
please ensure that the specified PMU events in the *itlbstats.sh* script are
available. You can verify this by looking up *perf list* or by using ocperf
(refer to the "ocperf" chapter below).

Building the default kernel
---------------------------

To test the objective of the thesis, a custom (default) kernel must be built
first. Here the kernel v5.10.178 (from the latest debian bullseye release) was
used as a base. The kernel was built as follows:

.. code::

   # Clone the Linux kernel repository and navigate to the cloned directory
   git clone --single-branch -b v5.10.178  git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git linux
   cd linux

   # create a config file

   ## Optional
   # You can use the existing configuration as a starting point
   cp /boot/config-$(uname -r) .config

   # deactivate features which occur in the existing configuration and stop
   # the compilation process
   scripts/config --set-str SYSTEM_TRUSTED_KEYS ""
   scripts/config --disable CONFIG_DEBUG_INFO_BTF
   ## Optional

   make -j`nproc`

   # install the new kernel to boot from
   sudo make modules_install install
   # or
   sudo sh -c 'make INSTALL_MOD_STRIP=1 modules_install && make install'

   # rename the compiled files in the boot partition to *5.10.178+default*
   cd /boot; sudo rename 's/178/178\+default/' *.178

Boot into the new kernel.

Start a workload test
---------------------

The scripts use *perf* and specific PMU events to determine performance
improvements for specific workloads. To initiate a workload test, use the
frontend wrapper script called *collect-stats.sh*, which provides a unified
testing procedure. Execute the following command to start the test:

::

   # if not done: install perf
   sudo apt install linux-tools-common linux-tools-generic
   ./collect-stats.sh

The script *itlbstat.sh* embedded within *collect-stats.sh* generates
*itlbstats-$(date -Iseconds).report* files. These files contain the collected
and counted values for the defined PMU events. Save the file(s) in a secure
location for later analysis.

At this stage, you can define additional tests. For example, if you want to
test and collect network throughput data, you can use the following command:

::

   ./collect-bandwidth.sh

This script will generate files named *bandwidth.perf*.

Generate a weighted call graph
------------------------------

To generate a weighted call graph for a running workload, you can use the
frontend wrapper script called collect-data.sh. This script aims to provide a
unified testing procedure. By default, a network workload is started. Execute
the following command to initiate the data collection:

::

   ./collect-data.sh

The script *graphrecord.sh*, which is embedded within the wrapper script, is
responsible for creating the file *callgraph-$(date -Iseconds).report*. This
file contains the weighted call graph data.

Generating a sorted list
------------------------

To create a custom linker script with which the kernel should be recompiled
you can utilize the generated file *callgraph-$(date -Iseconds).report* from
the data collection step. This report file can be converted in a linker
script via the *tools/hfsort-light* project. To load the submodule
and generate the linker script from the report file use:

::

   git submodule update --init --recursive   
   python tools/hfsort-light/hfsort.py --report callgraph-*.report \
             --template $(SRC_KERNEL)/arch/x86/kernel/vmlinux.lds

For further information and tooling see the *README.md* of the project.

The *hfsort.py* script employs the C3 heuristic for sorting the given report
file. You can find the original implementation in [3]. This script generates a
custom vmlinux.lds file that overwrites the original file. To recompile the
kernel with the custom linker script, enable the additional flag
*KCFLAGS=-ffunction-sections* and use the following command as an example:

::

   python tools/hfsort-light/hfsort.py $(args)
   cp vmlinux.lds $(SRC_KERNEL)/arch/x86/kernel/vmlinux.lds
   cd $(SRC_KERNEL)
   make KCFLAGS=-ffunction-sections -j`nproc`

Install the new kernel and boot into it. Start an additional workload test.

Analyse collected information
-----------------------------

To check whether the applied heuristic had a significant impact on
the PMU events, you can utilize the tools in *tools/evaluate-data*. The
python tools require *numpy* and *matplotlib* for the analysis. Use the
following example command to do this:

::

   # install the library via pip
   pip install matplotlib
   python tools/evaluate-data/run.py \
          --unoptimized-directory $(TEST)/unoptimized \
          --optimized-directory $(TEST)/optimized

For further information see the *README.md* in the *tools/evaluate-data*
folder.

ocperf
------

One can use *ocperf* from the *pmu-tools* repo [1] to easily check if an event
is supported on a processor. Official documentation on the PMU events which are
supported in an Intel generation can be found at [2].

For this *ocperf* downloads the latest PMU events of the found CPU generation
of [2] and assembles the real perf command with this information. That is why
all commandos which are possible with *perf* can also be used with *ocperf*.

::

   # check if PMU loaded and which events (here: Skylake events)
   $ sudo dmesg | grep PMU
   [    0.157217] Performance Events: PEBS fmt3+, Skylake events, 32-deep LBR, full-width counters, Intel PMU driver.

   # use ocperf
   $ ocperf stat -e ITLB_MISSES.MISS_CAUSES_A_WALK -a -- sleep 2
   Downloading https://raw.githubusercontent.com/intel/perfmon/main/mapfile.csv to mapfile.csv
   Downloading https://raw.githubusercontent.com/intel/perfmon/main/SKL/events/skylake_core.json to GenuineIntel-6-4E-core.json
   Downloading https://raw.githubusercontent.com/intel/perfmon/main/README.md to README.md
   Downloading https://raw.githubusercontent.com/intel/perfmon/main/LICENSE to LICENSE
   Downloading https://raw.githubusercontent.com/intel/perfmon/main/mapfile.csv to mapfile.csv
   Downloading https://raw.githubusercontent.com/intel/perfmon/main/SKL/events/skylake_core.json to GenuineIntel-6-4E-core.json
   Downloading https://raw.githubusercontent.com/intel/perfmon/main/SKL/events/skylake_uncore.json to GenuineIntel-6-4E-uncore.json

   perf stat -e cpu/event=0x85,umask=0x1,name=itlb_misses_miss_causes_a_walk/ -a -- sleep 2

   Performance counter stats for 'system wide':

          84,855      itlb_misses_miss_causes_a_walk

          2.002689352 seconds time elapsed


References
==========

[1] andikleen/pmu-tools https://github.com/andikleen/pmu-tools
[2] intel/perfmon https://github.com/intel/perfmon
[3] hhvm/hfsort https://github.com/facebook/hhvm/blob/master/hphp/util/hfsort.cpp
