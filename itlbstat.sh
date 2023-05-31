#!/usr/bin/env bash
#
# Copyright 2018 Netflix, Inc.
# Licensed under the Apache License, Version 2.0 (the "License")
#
# 08-Jan-2018   Brendan Gregg   Created this.
#
# Glossar:
#
# - PMH: Page Miss Handler
#
# Columns:
#
# - K_CYCLES: CPU Cycles x 1000
# - K_INSTR: CPU Instructions x 1000
# - IWALK: Page walk (of any size) caused by a code fetch
# - RET_ITLB: Retired instruction causes ITLB miss
# - K_ITLB_ACT: Number of cycles PMH are busy with a code fetch x 1000
# - ICACHE: Numebr of cycles code fetch is stalled due to L1 instruction cache
# - ICACHEM: Instruction fetch tag lookups that miss in the instruction cache
# - CPUU: Number of core cycles while the thread is not in a halt state
# - IWALK_COMP: Completed page walks (2M and 4M) caused by a code fetch
# - INS_RET_ANY: Number of instructions retired from execution
#
# Additionally, metrics recommended in Intels 'Runtime Performance
# Optimization Blueprint: Intel Architecture Optimization with large code
# pages' can be calculated from the above defined events:
#
# - ITLB_STALLS: Fraction of cycles the CPU was stalled due to ITLB misses
#     is calculated via: 100 * (ICACHE / CPUU)
# - ITLB_MPKI: Normalized value which can be used to compare different systems
#     is calculated via: 1000 (IWALK_COMP / INS_RET_ANY)
#

source $PWD/common.src

function usage {
        cat <<-END >&2
        USAGE: tlbstat [-c CMD] [-f FILE] [duration [interval]]
                         -c 'CMD'       # measure this command (quote it)
			 -f FILE        # generated output is saved to FILE
                         -I INTERVAL    # output header every interval in
					# secs (default disabled)
			 interval	# output results every interval in secs
					# (default 1)
                         duration       # total duration (default 9999)
          eg,
               tlbstat                  # show stats across all CPUs
               tlbstat 5                # show stats every 5 seconds
               tlbstat -c 'cksum /boot/*'  # measure run and measure this cmd
END
        exit
}

opt_cmd=0; opt_file=0;
cmd=""; file=""
hlines=0; # lines to repeat header

while getopts "c:f:I:h" opt
do
        case $opt in
        c)      opt_cmd=1; cmd=$OPTARG ;;
        f)      opt_file=1; file=$OPTARG ;;
	I)	hlines=$OPTARG;;
        h|?)    usage ;;
        esac
done
shift $(( $OPTIND - 1 ))

duration=${1:-9999}             # default semi-infinite seconds
secs=${2:-1}                    # default 1 second

# base target flags
target="--all-cpus -- sleep ${duration}"

# add optargs to target depending on set flag
(( opt_cmd )) && target="$cmd"
(( opt_file )) && [ -z "$file" ] && file="perf-stats"


# note that instructions is last on purpose, it triggers output
# cycles are twice as a workaround for an issue
perf stat -e cycles -e cycles \
	-e itlb_misses.miss_causes_a_walk \
        -e frontend_retired.itlb_miss \
        -e itlb_misses.walk_active \
        -e itlb_misses.walk_completed \
        -e cpu_clk_unhalted.thread \
        -e icache_64b.iftag_stall \
	-e icache_64b.iftag_miss \
        -e inst_retired.any \
        -e instructions \
        -I $(( secs * 1000 )) $target 2>&1 | awk \
        -v hlines=$hlines -v out="${file}.report" -v interval="$secs" '
        BEGIN {
                htxt = sprintf("%-10s %-10s %-10s %-10s %-10s %-10s %-10s %-12s %-10s %-10s",
                "K_CYCLES", "K_INSTR","IWALK", "RET_ITLB", "K_ITLB_ACT",
		"ICACHE", "ICACHEM", "CPUU", "IWALK_COMP", "INS_RET_ANY");

                if(out != ""){
                        file = out
                        print "Saving output to " out " ..."
			print "# Interval time in secs: " interval
                        printf("%s\n", htxt) > file
                }

                print htxt
                header = hlines
        }
        /invalid/ { print $0 }  # unsupported event
        { gsub(/,/, ""); }
        $3 == "cycles" { cycles = $2; }
        # counts:
        $3 == "itlb_misses.miss_causes_a_walk" { imwalk = $2 }
        $3 == "frontend_retired.itlb_miss" { itlb = $2  }
        # walk active cycles in at least one PMH cycles:
        $3 == "itlb_misses.walk_active" { itlbwc = $2; }
        $3 == "itlb_misses.walk_completed" { iwalk = $2; }
        $3 == "cpu_clk_unhalted.thread" { cpuu = $2; }
        $3 == "icache_64b.iftag_stall" { icac = $2; }
        $3 == "icache_64b.iftag_miss" { icacm = $2; }
        $3 == "inst_retired.any" { iret = $2; }
        $3 == "instructions" {
                if (--header == 0) {
                        print htxt
                        header = hlines
                }
                ins = $2
                if (cycles == 0) { cycles = 1 }  # PMCs are broken, or no events

                out = sprintf("%-10d %-10d %-10d %-10d %-10d %-10d %-10d %-12d %-10d %-10d",
                        cycles / 1000, ins / 1000,
                        imwalk,
			itlb,
                        itlbwc / 1000,
			icac,
			icacm,
			cpuu,
			iwalk,
			iret)
                if (file != ""){
                        printf("%s\n", out) >> file
                }
                print out
                # for older versions use system("")
                fflush();
        }
        END {
                close(file)
        }
'
