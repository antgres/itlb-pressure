# itlb-pressure
This repo contains the tooling for the master thesis *Analysis of the reduction
of ITLB cache pressure through code collocation based on the Linux kernel*
which can be found in the *docs* branch.

Read *TEST-INSTRUCTIONS.rst* for more information.

## Abstract

This thesis explores the potential for performance improvement by reducing
instruction lookaside buffer (ITLB) pressure through code collocation in the
kernel. The objective is to reorder frequently used caller-callee function
pairs within the *.text* section, aiming to increase the ITLB hit-rate and
subsequently minimize ITLB misses and page faults. Automatic methods, such as
the call chain clustering (C3) heuristic, are proposed to facilitate code
reorganization. The findings demonstrate the effectiveness of code collocation,
specifically with the utilization of the C3 heuristic, in reducing ITLB
pressure for specific workloads in the kernel. However, to establish broader
applicability, further testing with diverse configurations is recommended.

