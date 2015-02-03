#!/bin/bash

get_preclean_type()
{
    head -n 1 ${ANDROID_BUILD_TOP}/.lastbuild
}

# only allow submissions that are a single bacon following a clean/clobber or novo
check_build_validity()
{
    if [ ! -f ${ANDROID_BUILD_TOP}/.lastbuild ] || [ `cat ${ANDROID_BUILD_TOP}/.lastbuild | wc -l` -ne 2 ]; then
        return 1
    fi
    if get_preclean_type | grep -q clobber || get_preclean_type | grep -q clean || get_preclean_type | grep -q novo; then
        return 0
    fi
    return 1
}

if ! check_build_validity; then exit 0; fi

BUILD_PROP=$1/system/build.prop
end_time=$(date +"%s")
start_time=`cat ${ANDROID_BUILD_TOP}/.lastbuildstart`
GIT_NAME=`git config --global user.name`
HOSTNAME=`hostname`
PRODUCT=`cat $BUILD_PROP | grep ro.product.name | sed 's/.*=//g'`
LUNCHTYPE=`cat $BUILD_PROP | grep ro.build.type | sed 's/.*=//g'`
tdiff=$(($end_time-$start_time))
BUILD_SECONDS=$((tdiff))
SUBMISSION_STAMP=`date +"%F %T"`
DISK_INFO=`df -h`
MEM_INFO=`cat /proc/meminfo`
CPU_INFO=`cat /proc/cpuinfo`
SQLSTUFF="mysql -u vanirbuilder --password=vanirwillpumpyouup -h mysql.vanir.co vanirbuildlog -e "
$SQLSTUFF "CREATE TABLE IF NOT EXISTS Builds ( ID int NOT NULL AUTO_INCREMENT PRIMARY KEY, SUBMISSION_STAMP timestamp NOT NULL, HOSTNAME varchar(255), GIT_NAME varchar(255), PRECLEAN_TYPE varchar(255), PRODUCT varchar(255), LUNCHTYPE varchar(255), BUILD_SECONDS int NOT NULL, DISK_INFO varchar(2048), MEM_INFO varchar(2048), CPU_INFO varchar(2048) );"
$SQLSTUFF "INSERT INTO Builds ( SUBMISSION_STAMP, HOSTNAME, GIT_NAME, PRECLEAN_TYPE, PRODUCT, LUNCHTYPE, BUILD_SECONDS, DISK_INFO, MEM_INFO, CPU_INFO ) VALUE ( '${SUBMISSION_STAMP}', '${HOSTNAME}', '${GIT_NAME}', '$(get_preclean_type)', '${PRODUCT}', '${LUNCHTYPE}', '${BUILD_SECONDS}', '${DISK_INFO}', '${MEM_INFO}', '${CPU_INFO}' );"
exit 0
