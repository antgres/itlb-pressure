import numpy as np

from src.calculations import metric_calculation
from src.OutputFormater import print_comparison
from src.common import SimpleNamespaceWrapper
from src.ParseData import split_into_values, calculate_geo_mean
from src.graphs import create_histogram


def calc_metrics(opt, unopt, namespace=False):
    if namespace:
        opt = SimpleNamespaceWrapper(opt)
        unopt = SimpleNamespaceWrapper(unopt)

    metrics = {
        "opt_k_ipc": metric_calculation(
            opt.k_cycles, opt.k_instr, "ipc"
        ),
        "unopt_k_ipc": metric_calculation(
            unopt.k_cycles, unopt.k_instr, "ipc"
        ),
        "opt_itlb_stall": metric_calculation(
            opt.icache, opt.cpuu, "itlb_stall"
        ),
        "unopt_itlb_stall": metric_calculation(
            unopt.icache, unopt.cpuu, "itlb_stall"
        ),
        "opt_itlb_mpki": metric_calculation(
            opt.iwalk_comp, opt.ins_ret_any, "itlb_mpki"
        ),
        "unopt_itlb_mpki": metric_calculation(
            unopt.iwalk_comp, unopt.ins_ret_any, "itlb_mpki"
        ),
    }

    return SimpleNamespaceWrapper(metrics)


def create_all_graphs(opt, unopt, metric):
    create_histogram("ITLB Stall Metric",
                     metric.opt_itlb_stall,
                     metric.unopt_itlb_stall)

    create_histogram("ITLB MPKI Metric",
                     metric.opt_itlb_mpki,
                     metric.unopt_itlb_mpki)

    create_histogram("itlb_misses.miss_causes_a_walk",
                     opt.iwalk,
                     unopt.iwalk)

    create_histogram("itlb_misses.walk_active",
                     opt.k_itlb_act,
                     unopt.k_itlb_act)

    create_histogram("itlb_misses.walk_completed",
                     opt.iwalk_comp,
                     unopt.iwalk_comp)

    create_histogram("frontend_retired.itlb_miss",
                     opt.ret_itlb,
                     unopt.ret_itlb)

    create_histogram("icache_64b.iftag_stall",
                     opt.icache,
                     unopt.icache)

    create_histogram("icache_64b.iftag_miss",
                     opt.icachem,
                     unopt.icachem)


def print_information(opt, unopt, metrics, method, method_name):
    print_comparison(method,
                     f"{method_name} itlb_misses.miss_causes_a_walk",
                     opt.iwalk,
                     unopt.iwalk,
                     int)

    print_comparison(method,
                     f"{method_name} itlb_misses.walk_active",
                     opt.k_itlb_act,
                     unopt.k_itlb_act,
                     int)

    print_comparison(method,
                     f"{method_name} itlb_misses.walk_completed",
                     opt.iwalk_comp,
                     unopt.iwalk_comp,
                     int)

    print_comparison(method,
                     f"{method_name} frontend_retired.itlb_miss",
                     opt.ret_itlb,
                     unopt.ret_itlb,
                     int)

    print_comparison(method,
                     f"{method_name} icache_64b.iftag_miss",
                     opt.icachem,
                     unopt.icachem,
                     int)

    print_comparison(method,
                     f"M-{method_name} ITLB Stall",
                     metrics.opt_itlb_stall,
                     metrics.unopt_itlb_stall,
                     float)

    print_comparison(method,
                     f"M-{method_name} ITLB MPKI",
                     metrics.opt_itlb_mpki,
                     metrics.unopt_itlb_mpki,
                     float)

    print_comparison(method,
                     f"{method_name} instructions",
                     opt.k_instr,
                     unopt.k_instr,
                     int, "up")

    print_comparison(method,
                     f"{method_name} cycles",
                     opt.k_cycles,
                     unopt.k_cycles,
                     int, "up")

    print_comparison(method,
                     f"{method_name} IPC",
                     metrics.opt_k_ipc,
                     metrics.unopt_k_ipc,
                     float, "up")


def print_geometric_mean(raw_optimized_data, raw_unoptimized_data):
    np_opt, np_unopt = \
        split_into_values(raw_optimized_data, no_namespace=True), \
            split_into_values(raw_unoptimized_data, no_namespace=True)

    metric_list = [
        calc_metrics(opt, unopt, namespace=True)
        for opt, unopt in zip(np_opt, np_unopt)
    ]

    opt = calculate_geo_mean(np_opt)
    unopt = calculate_geo_mean(np_unopt)
    metric = calculate_geo_mean(metric_list, namespace=True)

    def dummy_function(value):
        return value

    print_information(opt, unopt, metric, dummy_function, "Geo")


def create_results(args, raw_optimized_data, raw_unoptimized_data):
    """
    Events defined in itlbstat.sh
    ---------------------------

    cycles [K_CYCLES]
        Counted cycles

    instructions [K_INSTR]
        Retired instructions

    inst_retired.any [INS_RET_ANY]
        Counts the number of instructions retired from execution. For
        instructions that consist of multiple micro-ops, Counts the
        retirement of the last micro-op of the instruction. Counting
        continues during hardware interrupts, traps, and inside interrupt
        handlers

    itlb_misses.miss_causes_a_walk [IWALK]
        Counts page walk (of any size) caused by a code fetch

    frontend_retired.itlb_miss [RET_ITLB]
        Increases counter if a retired instructions creates a iTLB miss in the
        first-level ITLB and the (shared) second-level TLB (STLB)

    itlb_misses.walk_active [K_ITLB_ACT]
        Cycles when at least one Page Miss Handler is busy with a page walk for
        code (instruction fetch) request. Extended page walk duration are
        excluded in Skylake microarchitecture

    itlb_misses.walk_completed [IWALK_COMP]
        Counts completed page walks (2M and 4M page sizes) caused by a code
        fetch. This implies it missed in the ITLB and further levels of TLB.
        The page walk can end with or without a fault.

    cpu_clk_unhalted.thread [CPUU]
        Counts the number of core cycles while the thread is not in a halt
        state. The thread enters the halt state when it is running the HLT
        instruction

    icache_64b.iftag_stall [ICACHE]
        Cycles where a code fetch is stalled due to L1 instruction cache

    icache_64b.iftag_miss [ICACHEM]
        Instruction fetch tag lookups that miss in the instruction cache (L1I).
        Counts at 64-byte cache-line granularity.

    Metrics
    -------

     ITLB Stall Metric [itlb_stall]
        Represents the percentage of cycles the CPU was stalled due to
        instruction TLB misses

     ITLB Misses Per Kilo Instructions [itlb_mpki]
         Represents normalization of the ITLB misses against number of
         instructions. Allows comparison between different systems
    """

    np_opt, np_unopt = \
        split_into_values(raw_optimized_data, single=True), \
            split_into_values(raw_unoptimized_data, single=True)

    metrics = calc_metrics(np_opt, np_unopt)

    print_information(np_opt, np_unopt, metrics, np.mean, "Mean")
    print("------------")
    print_information(np_opt, np_unopt, metrics, np.median, "Median")
    print("------------")
    print_geometric_mean(raw_optimized_data, raw_unoptimized_data)

    if args.graphs:
        create_all_graphs(np_opt, np_unopt, metrics)
