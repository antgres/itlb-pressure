#! /usr/bin/env bash

source "$PWD/common.src"

TIME=${1:-180}
[ -z "$TIME" ] && die "No time given"

DEFAULT_WARMUP_TIME=$(( 60 * 10 ))
WARMUP_TIME=${2:-$DEFAULT_WARMUP_TIME}

# start workload
$PWD/workload/network.sh -t $(( TIME + WARMUP_TIME )) -N 20 -n 0 &

echo "Wait ${WARMUP_TIME} seconds to warmup..."
sleep $WARMUP_TIME

echo "Start data collection..."
$PWD/graphrecord.sh \
    -a -r -t $TIME \
    -o "$PWD/callgraph-$(date -Iseconds)" \
    -m 1024M \
    -f 3000 \

# from common.src
clear_cache
