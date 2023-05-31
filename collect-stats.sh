#!/usr/bin/env bash

source "$PWD/common.src"

DEFAULT_TIME=$(( 3600 * 6 ))
TIME=${1:-$DEFAULT_TIME}
[ -z "$TIME" ] && die "No time given"

DEFAULT_WARMUP_TIME=$(( 60 * 10 ))
WARMUP_TIME=${2:-$DEFAULT_WARMUP_TIME}

LOOPS=${3:-5}

for i in $(seq 1 $LOOPS); do
  # start workload
  $PWD/workload/network.sh -t $(( TIME + WARMUP_TIME )) \
                           -N 20 -n 2024 &

  echo "Wait ${WARMUP_TIME} seconds to warmup..."
  sleep $WARMUP_TIME

  # start workload and collect
  echo "Start data collection..."
  $PWD/itlbstat.sh \
        -f "$PWD/$i-itlbstats-$(date -Iseconds)" \
        $TIME

  # from common.src
  clear_cache
done
