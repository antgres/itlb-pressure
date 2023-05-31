#!/usr/bin/env bash

source "$PWD/common.src"

DEFAULT_TIME=$(( 3600 * 1 ))
TIME=${1:-$DEFAULT_TIME}
[ -z "$TIME" ] && die "No time given"

DEFAULT_WARMUP_TIME=$(( 60 * 10 ))
WARMUP_TIME=${2:-$DEFAULT_WARMUP_TIME}

LOOPS=${3:-5}

COMMON_START="$PWD/workload/network.sh -B \
-n 2024\
-w"

for i in $(seq 1 $LOOPS); do
  OUTPUT="$i-bandwidth.perf"

  # start warmup
  echo "Wait ${WARMUP_TIME} seconds to warmup..."
  $COMMON_START -t $WARMUP_TIME -o $OUTPUT

  # start workload
  echo "Start data collection..."
  $COMMON_START -t $TIME -o $OUTPUT

  # from common.src
  clear_cache
done
