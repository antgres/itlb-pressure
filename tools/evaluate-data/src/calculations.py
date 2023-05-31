#!/usr/bin/env python

import numpy as np

if __name__ != '__main__':
    from src.common import adjust_arrays


def metric_calculation(numerator, denominator, type):
    numerator, denominator = adjust_arrays(numerator, denominator)

    if type == "ipc":
        return calc_ipc(numerator, denominator)
    elif type == "itlb_stall":
        return calc_itlb_stall(numerator, denominator)
    elif type == "itlb_mpki":
        return calc_itlb_mpki(numerator, denominator)
    else:
        return None


def calc_ipc(instr_array, cycles_array):
    return instr_array / cycles_array


def calc_itlb_stall(icache_array, cpu_unhalted_array):
    return 100 * (icache_array / cpu_unhalted_array)


def calc_itlb_mpki(iwalk_completed_array, instr_ret_any_array):
    return 1000 * (iwalk_completed_array / instr_ret_any_array)


def scipy_geo_mean(iterable):
    """
    Compute the weighted geometric mean in logarithmic form. Copied
    implementation from python package scipy.stats.gmean.
    """

    iterable = np.asarray(iterable)

    with np.errstate(divide='ignore'):
        log_iter = np.log(iterable)

    return np.exp(np.mean(log_iter))


if __name__ == '__main__':
    import sys

    stdin = sys.stdin.read()

    if not stdin:
        output = 'NULL'
    else:
        # stdin has the form "8.19,6.37,6.98,7.40,5.96,"
        values = [float(value.strip())
                  for value in stdin.split(',')
                  if value]
        output = str(scipy_geo_mean(values))

    sys.stdout.write(output)
