#!/usr/bin/env bash

SRC_ROOT="$(dirname "${BASH_SOURCE}")"
source $SRC_ROOT/../common.src

function usage {
    cat <<EOM >&2
Usage: $(basename "$0") [-h] [-n] [-B [-o OUTPUT]] [-t DURATION]
                        [-N AMOUNT_PAIRS] [-I INTERFACE] [-i IP] [-n NIC_VALUE]

OPTIONS
        -h              Print usage.
        -t              Total time in seconds in which data is transmitted.
                        [Default: 30]
        -i              IPv4 address to which the servers and clients are
                        binded to. If no IPv4 is provided then an IPv4 address
                        is guessed from the system settings.
        -N              Number of server/client double-pairs which are to be
                        created.
                        The value is multiplied by four because a server and
                        client is created each for transmittion and receiving.
                        For three pairs a total of twelve servers ans clients
                        are created.
                        [Default: 3]
        -B              Start a bandwidth test with a single server and
                        client and save output from the client to the file
                        *bandwidth.perf*.
        -o              Only available for bandwidth tests. Specify the name
                        of the output file.
        -I              Interface from which the ring buffer is to be changed.
                        If no interface is given then an Interface is guessed
                        from the system settings.
        -n              Value which defines the size of a INTERFACES tx and rx
                        ring buffer via *ethtool -G INTERFACE rx n tx n*.
                        If no Interface is given then an Interface is guessed
                        from the system settings.
        -w              If flag is specified the script waits for all
                        applications to finish.

REMARK
	This workload is based on iperf3 v3.9. It therefore uses the --bind
	flag to bind the applications to a specific network interface.

	For the guessing of the IPv4 and the corresponding INTERFACE the
	package *iproute2* with the command *ip route get* is used.
EOM
    exit 1
}


IP=""; INTERFACE="";
NUM_SERVER="3"; # times 2 (with reverse)
TEST_DURATION="30" # seconds
CHANGE_NIC=0; NIC_VALUE=0;
WAIT=0;
BANDWIDTH=0;
OUTPUT="bandwidth.perf"

while getopts "ht:I:i:N:n:Bo:w" arg; do
  case $arg in
    h)
      usage
      ;;
    t)
      TEST_DURATION="${OPTARG}"
      ;;
    I)
      INTERFACE="${OPTARG}"
      ;;
    i)
      IP="${OPTARG}"
      ;;
    N)
      NUM_SERVER="${OPTARG}"
      ;;
    n)
      CHANGE_NIC=1
      NIC_VALUE="${OPTARG}"
      ;;
    w)
      WAIT=1
      ;;
    B)
      BANDWIDTH=1
      ;;
    o)
      (( BANDWIDTH )) &&\
       OUTPUT="${OPTARG}"
       ;;
    *)
      echo "Invalid argument '${arg}'" >&2
      usage
      ;;
  esac
done

guess_network_information(){
  # guess the interface and the IPv4 address
  local result
  result="$(ip -4 -oneline route get 8.8.8.8 | awk '{print $5 "\t" $7}')"

  if [ -z "${IP}" ]; then
    IP="$(echo "$result" | cut -f2)"
    printf 'Found the IPv4: %s\n' "$IP"
  fi

  if [ -z "${INTERFACE}" ]; then
    INTERFACE="$(echo "$result" | cut -f1)"
    printf 'Found the interface: %s\n' "$INTERFACE"
  fi
}

set_interface_buffer_rate(){
  local interface="${1}"
  local nic_value="${2}"
  local ethtool="/usr/sbin/ethtool"

  # set new tx and rx
  /usr/bin/sudo sh -x -c "$ethtool --set-ring $interface rx $nic_value tx $nic_value"
}

change_nic(){
  if [ -n "$(which ethtool >/dev/null 2>&1)" ]; then
    set_interface_buffer_rate "${INTERFACE}" "${NIC_VALUE}"
  else
    echo "Option 'change nic' set but no tool 'ethtool' available"
  fi
}

if [ -z "${IP}" ] || [ -z "${INTERFACE}" ]; then
  guess_network_information
fi

(( CHANGE_NIC )) && change_nic

if [ -z "$IP" ]; then
  # if at this stage no IPv4 is provided
  # then just stick to localhost
  IP="localhost"
fi

# server parameter
IPERF_SERVER_PARAMS="--server \
--daemon \
--one-off \
--bind $IP"

IPERF_CLIENT_PARAMS="--client $IP \
--zerocopy \
--time $TEST_DURATION"

# set nice value for all instances
NICE="/usr/bin/sudo nice -n -5"

test_bandwidth(){
	local default="--format k"

	IPERF_SERVER_PARAMS="$IPERF_SERVER_PARAMS $default"
	IPERF_CLIENT_PARAMS="$IPERF_CLIENT_PARAMS $default"

	$NICE iperf3 $IPERF_SERVER_PARAMS --port 6000 >/dev/null
	$NICE iperf3 $IPERF_CLIENT_PARAMS --port 6000 > "$OUTPUT"

	exit 0
}

# start bandwidth test
(( BANDWIDTH )) && test_bandwidth

# start servers
for i in $(seq 1 $NUM_SERVER); do
	S_PORT=$(( 6000 + i ))
	R_PORT=$(( 6000 + NUM_SERVER + i ))

	$NICE iperf3 $IPERF_SERVER_PARAMS --port $S_PORT >/dev/null
	$NICE iperf3 $IPERF_SERVER_PARAMS --port $R_PORT >/dev/null
done

# start clients
for i in $(seq 1 $NUM_SERVER); do
	TX_PORT=$(( 6000 + i ))
	RX_PORT=$(( 6000 + NUM_SERVER + i ))

	$NICE iperf3 $IPERF_CLIENT_PARAMS --port $TX_PORT >/dev/null &
	$NICE iperf3 $IPERF_CLIENT_PARAMS --port $RX_PORT --reverse >/dev/null &
done

# if wait flag is specified wait for all programs
(( WAIT )) && wait -n
