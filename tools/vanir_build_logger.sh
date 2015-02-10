#!/bin/bash

get_preclean_type()
{
    head -n 1 ${ANDROID_BUILD_TOP}/.lastbuild
}

# only allow submissions that are a single bacon following a clean/clobber or novo
check_build_validity()
{
    if [ "`which mysql`" = "" ]; then
        echo "WANT TO SEE HOW YOUR RIG STACKS UP TO NUKE'S?? 'sudo apt-get install mysql-client'"
        return 1
    fi
    if [ ! -f ${ANDROID_BUILD_TOP}/.lastbuild ] || [ `cat ${ANDROID_BUILD_TOP}/.lastbuild | wc -l` -ne 2 ]; then
        return 1
    fi
    if get_preclean_type | grep -q clobber || get_preclean_type | grep -q clean || get_preclean_type | grep -q novo; then
        return 0
    fi
    return 1
}

if [ $IM_A_SACK_OF_CRAP ] || ! check_build_validity; then exit 0; fi

BUILD_PROP=$1/system/build.prop
end_time=$(date +"%s")
start_time=`cat ${ANDROID_BUILD_TOP}/.lastbuildstart`
VERSION=1
GIT_NAME=`git config --global user.name`
HOSTNAME=`hostname`
PRODUCT=$TARGET_PRODUCT
LUNCHTYPE=`cat $BUILD_PROP | grep ro.build.type | sed 's/.*=//g'`
tdiff=$(($end_time-$start_time))
BUILD_SECONDS=$((tdiff))
SUBMISSION_STAMP=`date +"%F %T"`
DISK_INFO=`df -h`
MEM_INFO=`cat /proc/meminfo`
CPU_INFO=`cat /proc/cpuinfo`
if [ $USE_CCACHE ]; then
    CCACHE_STATUS="ENABLED"
    CCACHE_SIZE="`${ANDROID_BUILD_TOP}/ccache/ccache -s | awk 'NR==12 { print $3, $4 }'`"
    CCACHE_FULL="`${ANDROID_BUILD_TOP}/ccache/ccache -s`"
else
    CCACHE_STATUS="DISABLED"
fi

curl -XPOST \
    -d version=$VERSION \
    --data-urlencode stamp="$SUBMISSION_STAMP" \
    -d git_name=$GIT_NAME \
    -d hostname=$HOSTNAME \
    -d product=$PRODUCT \
    -d lunchtype=$LUNCHTYPE \
    -d preclean_type=$(get_preclean_type) \
    -d build_seconds=$BUILD_SECONDS \
    -d ccache_status="${CCACHE_STATUS}" \
    -d ccache_size="${CCACHE_SIZE}" \
    --data-urlencode disk_info="${DISK_INFO}" \
    --data-urlencode mem_info="${MEM_INFO}" \
    --data-urlencode cpu_info="${CPU_INFO}" \
    --data-urlencode ccache_full="${CCACHE_FULL}" \
    http://www.vanir.co/log_build.php 2> /dev/null && echo


exit 0
