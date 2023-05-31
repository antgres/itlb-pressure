#!/usr/bin/env bash

function usage {
  cat <<EOM >&2
Usage: $(basename "$0") [-h] [-o OPTIMIZED_FOLDER] [-u UNOPTIMIZED_FOLDER]

DESCRIPTION
	Calculates the geometric mean from bandwidth.perf files in the
        specified folder which are created by iperf3.

        For this files the geometric mean of the throughput (original: bitrate)
        and the total bytes transferred (original: Transfer) will be
        calculated.

OPTIONS
	-h                 Print usage and exit.
	-o                 Path of folder with optimized data.
	-u                 Path of folder with unoptimized data.

EOM
  exit 1
}

OPT_FOLDER=""
UNOPT_FOLDER=""

while getopts "ho:u:" arg; do
  case $arg in
  h)
    usage
    ;;
  o)
    OPT_FOLDER="${OPTARG}"
    ;;
  u)
    UNOPT_FOLDER="${OPTARG}"
    ;;
  *)
    printf 'WARN: Unknown option (ignored): %s\n' "${arg}" >&2
    usage
    exit 1
    ;;
  esac
done

get_values_from_lists() {

  # iperf3 with --bidir flag enabled has the following output:
  #
  # - - - - - - - - - - - - - - - - - - - - - - - - -
  # [ ID][Role] Interval           Transfer     Bitrate         Retr
  # [  5][TX-C]   0.00-3600.00 sec  6.96 TBytes  17003591 Kbits/sec   27             sender
  # [  5][TX-C]   0.00-3600.04 sec  6.96 TBytes  17003404 Kbits/sec                  receiver
  # [  7][RX-C]   0.00-3600.00 sec  8.19 TBytes  20003157 Kbits/sec   12             sender
  # [  7][RX-C]   0.00-3600.04 sec  8.19 TBytes  20002917 Kbits/sec                  receiver
  #
  #
  # To extract the values use the following values:
  #   awk:
  #     - Throughput (example: Bitrate): field=7
  #     - Total bytes transferred (example: Transfer): field=5
  #
  #   grep -E:
  #     - Client to Server, upload: direction='TX.*sender'
  #     - Client to Server, download: direction='RX.*sender'
  #

  local folder="${1}"
  local direction="${2}"
  local field="${3}"
  local message="${4}"

  local row="${direction}.*sender"

  values="$(tail "$folder"/*.perf | grep -E $row |
    awk -v field="$field" 'BEGIN { ORS="," }; { print $field }' |
    python src/calculations.py)"

  if [ "$values" == "NULL" ]; then
    printf "%s: NULL\n" "$message"
  else
    printf "%s: %.3f\n" "$message" "$values"
  fi
}

get_throughput() {
  local folder="${1}"
  local row="${2}"
  local case="${3}"

  get_values_from_lists "$folder" "$row" 7 \
    "$case - Throughput (kbit/sec)"
}

get_bytes_transferred() {
  local folder="${1}"
  local row="${2}"
  local case="${3}"

  get_values_from_lists "$folder" "$row" 5 \
    "$case - Total bytes transferred (TB)"
}

get_values() {
  local folder="${1}"
  local case="${2}"

  get_throughput "$folder" "TX" "$case"
  get_bytes_transferred "$folder" "TX" "$case"
}

# get unoptimized values
if [ -n "${UNOPT_FOLDER}" ]; then
  get_values "$UNOPT_FOLDER" "unoptimized"
else
  echo "No unoptimized folder specified. Skipping."
fi

# get optimized values
if [ -n "${OPT_FOLDER}" ]; then
  get_values "$OPT_FOLDER" "optimized"
else
  echo "No optimized folder specified. Skipping."
fi
