#!/usr/bin/env bash
#
# Build xfstests
# --------------
#
# FROM https://git.kernel.org/pub/scm/fs/xfs/xfstests-dev.git/tree/README
#
# $ sudo apt install xfslibs-dev uuid-dev libtool e2fsprogs \
#	       automake gcc libuuid1 quota attr libattr1-dev \
#	       libacl1-dev libaio-dev xfsprogs libgdbm-dev \
#              gawk fio dbench
#
# $ git clone https://git.kernel.org/pub/scm/fs/xfs/xfstests-dev.git
# $ cd xfstests-dev
# $ make
# $ sudo make install # to install test, libs and utils
#
# Depending on the tested file structure and the used distrubution
# additonal packages are needed. Check the xfs/xfstests-dev/README
# for information.
#
# Test devices
# ------------
#
# The xfstests test suite uses one or two block devices; one is named TEST
# and must be present, and the other is named SCRATCH, and is optional.
# Most tests use either the TEST or the SCRATCH device, although there
# are a few tests that use both devices.
#
# The SCRATCH device is reformatted by tests which need to use the SCRATCH
# device. Individual tests may not assume that there is a valid file system
# on the SCRATCH device. In contrast, the TEST device is never formatted by
# xfstests, and is intended to be a long lived, “aged” file system.
#
# For most ext4 file systems configurations, the TEST and SCRATCH device
# should be 5GB. Smaller, and some tests may not run correctly. Larger, and
# the tests will take a long time to run --- especially those tests that
# need to fill the file system to test ENOSPC handling. There are a few
# file system configurations for ext4 (most notable, bigalloc_4k) which
# require a 20GB test and scratch device.
#
# FROM repo tytso/xfstests-bld under Documentation/what-is-xfstests.md
#
# Add and run tmpfs tests
# -----------------------
#
# tmpfs is a file system which keeps all of its files in virtual memory. [1]
# The tmpfs facility was added as a successor to the older ramfs facility,
# which did not provide limit checking or allow for the use of swap space. [2]
#
# To mount a tmpfs and run a test on it with xfstest use:
#
# $ sudo mount -t tmpfs -o size=1G ramdisk /mnt/ramdisk
# $ sudo df -haT # look at the mounted tmpfs
#
# ramdisk    tmpfs    1.0G     0  1.0G   0% /mnt/ramdisk
#
# $ export TEST_DIR='/mnt/ramdisk'; \
#   export TEST_DEV='/dev/shm'; \
#   sudo xfstests-dev/check -tmpfs
#
# Set configs
# -----------
#
# To make tests repeatable a *local.config* can also be created which
# defines the configurations beforehand and which can define multiple
# filesystems in a single run. More details can be found under
# *README.config-sections*
#
# References
# ----------
#
# [1] https://www.kernel.org/doc/html/latest/filesystems/tmpfs.html
# [2] https://man7.org/linux/man-pages/man5/tmpfs.5.html
#

SRC_ROOT="$(dirname "${BASH_SOURCE}")"
source $SRC_ROOT/../common.src

function usage {
    cat <<EOM >&2
Usage: $(basename "$0") [-t TMPFS_SIZE] [-T TMPFS_LOCATION] [-s SCRATCH_SIZE]
                        [-S SCRATCH_LOCATION] [-R REPO_LOCATION]

DESCRIPTION
	This script is a wrapper around xfstest, which is a file system
	regression test suite. It creates two tmpfs TEST and
	SCRATCH with corresponding folders /test and /scratch and starts
	generic tmpfs xfstests with 'check -tmpfs'.

OPTIONS
	-h 		Print usage.
        -t              If a new TEST tmpfs is created, create it with a
			specified size in GB.
			[Default: 3]
        -T              Mount a new TEST tmpfs device at the specified
			location. Checks beforehand if the folder already
			exists and if it does exit.
			[Default: /test]
        -s              If a new SCRATCH tmpfs is created, create it with a
			specified size in GB.
			[Default: 3]
        -S              Mount a new SCRATCH tmpfs device at the specified
			location. Checks beforehand if the folder already
			exists and if it does exit.
			[Default: /scratch]
        -R              If the xfstests-dev suite is not in the same folder
			a new location can be assigned for development reasons
			[Default: .]

EOM
    exit 1
}

TEST_SIZE="3"; TEST_LOCATION="/test";
SCRATCH_SIZE="3"; SCRATCH_LOCATION="/scratch";
TEST_NAME="test"; SCRATCH_NAME="scratch";
REPO_LOCATION=".";

while getopts "ht:T:s:S:R:" arg; do
  case $arg in
    h)
      usage
      ;;
    t)
      TMPFS_SIZE="${OPTARG}"
      ;;
    T)
      TMPFS_LOCATION="${OPTARG}"
      ;;
    s)
      SRCATCH_SIZE="${OPTARG}"
      ;;
    S)
      SCRATCH_LOCATION="${OPTARG}"
      ;;
    R)
      REPO_LOCATION="${OPTARG}"
      ;;
    *)
      echo "Invalid argument '${arg}'" >&2
      usage
      ;;
  esac
done

create_tmpfs(){
	# creates a tmpfs with assigned size and location.
	# Additionally the flag *remount* is set which remounts
	# tmpfs without losing the data.
	local name="${1}"
	local location="${2}"
	local size="${3}"

	local addflags=""
	if [ $# -eq 4 ]; then
		# if the number of argument is equal to four
		# a flag was given
		local addflags=",${4}"
	fi

	# add '-o x-gvfs-show' to show tmpfs in user space
	sudo sh -x -c "mount -t tmpfs -o size=${size}G${addflags} ${name} ${location}"
}

check_and_create_tmpfs(){
	local name="${1}"
	local location="${2}"
        local size="${3}"

	if [[ -z $(df -a --output=source,fstype,target | grep tmpfs | grep "${name}" 2>/dev/null) ]]; then
		# check if something is mounted already on this location
		# if not try to create a tmpfs.
		create_tmpfs "$@"
	fi
}

create_folder(){
	local location="${1}"
	local name="${2}"

	read -p "Create a new ramdisk '${name}' at ${location} [y/n]? " -n 1 -r

	if [[ $REPLY =~ ^[Yy]$ ]]; then
		sh -x -c "mkdir -p ${location}"
	else
		die "Not allowed to create."
	fi
}

# check if folder already exists and if not create a folder
if [ ! -d "${TEST_LOCATION}" ]; then
	create_folder "${TEST_LOCATION}" "${TEST_NAME}"
fi
check_and_create_tmpfs "${TEST_NAME}" "${TEST_LOCATION}" "${TEST_SIZE}"

if [ ! -d "${SCRATCH_LOCATION}" ]; then
	create_folder "${SCRATCH_LOCATION}" "${SCRATCH_NAME}"
fi
check_and_create_tmpfs "${SCRATCH_NAME}" "${SCRATCH_LOCATION}" "${SCRATCH_SIZE}"


# set values
export TEST_DIR="${TEST_LOCATION}"
export TEST_DEV="${TEST_NAME}"
export SCRATCH_MNT="${SCRATCH_LOCATION}"
export SCRATCH_DEV="${SCRATCH_NAME}"

printf "Starting tests.\n";

# if no seperate location for the xfstest-dev is defined
# assume ./check is available in the same folder
[ -z "${REPO_LOCATION}" ] && REPO_LOCATION="."

sudo sh -x -c "cd ${REPO_LOCATION}; ./check -tmpfs"
