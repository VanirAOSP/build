#!/bin/bash

# nuclearmistake 2013

export TARGET_KERNEL_SOURCE=

#breadth first search through included BoardConfig(Common)s until TARGET_KERNEL_SOURCE is found
bfs()
{
    local frontier=""
#    echo "bfs currently @ $*"
    for x in $*; do
        if [ `cat $x | grep TARGET_KERNEL_SOURCE | wc -l` -gt 0 ]; then
            if [ `cat $x | grep TARGET_KERNEL_SOURCE | grep TARGET_KERNEL_VERSION | wc -l` -gt 0 ]; then
                export TARGET_KERNEL_VERSION="`cat $x | grep TARGET_KERNEL_VERSION | sed 's/.*:=//g' | sed 's/[\t ]*//g' | head -n 1`"
            fi
            export TARGET_KERNEL_SOURCE="`cat $x | grep TARGET_KERNEL_SOURCE | sed 's/.*:=//g' | sed 's/[\t ]*//g' | sed 's/(//g' | sed 's/)//g' | head -n 1`"
            export TARGET_KERNEL_SOURCE=`eval echo $TARGET_KERNEL_SOURCE`
            return 0
        fi
        for y in `cat $x | grep include | grep device | grep Board | grep Config | sed 's/\-*include //g'`; do
            frontier="$frontier $y"
        done
    done
    frontier="`echo $frontier | sed 's/  / /g'`"
    [ `echo "$frontier" | wc -w` -gt 0 ] && bfs $frontier || return 1
}

device=`echo $* | sed 's/.*_//g'`

devicedir=`find device -name '*'"$device" -type d | head -n 1` #if we get more than one result, then it\'s a bad day in the magical forest
if [ ! $devicedir ] || [ `echo $devicedir | wc -c` -le 1 ]; then
    devicedir=`find device -name "$device"'*' -type d | head -n 1`
fi
if [ ! $devicedir ] || [ `echo $devicedir | wc -c` -le 1 ]; then
    echo "$device IS A SACK OF CRAP AND SO ARE YOU."
    exit 1
fi

start=""
[ -e $devicedir/BoardConfigCommon.mk ] && start="$devicedir/BoardConfigCommon.mk"
[ -e $devicedir/BoardConfig.mk ] && start="$start $devicedir/BoardConfig.mk"
[ -e $devicedir/BoardCommonConfig.mk ] && start="$start $devicedir/BoardCommonConfig.mk"
bfs $start

if [ ! $TARGET_KERNEL_SOURCE ]; then
    TARGET_KERNEL_SOURCE=`echo $devicedir | sed -e 's/^device/kernel/g'`
fi

kernelsource="android_`echo $TARGET_KERNEL_SOURCE | sed 's/\//_/g'`"

source .repo/manifests/kernel_special_cases.sh $device

if [ ! -e .repo/local_manifests ] || [ ! -e .repo/local_manifests/bottleservice.xml ]; then
    mkdir -p .repo/local_manifests
    echo '<?xml version="1.0" encoding="UTF-8"?>
<manifest>
</manifest>' > .repo/local_manifests/bottleservice.xml
fi
if [ `cat .repo/local_manifests/bottleservice.xml | grep "name=\"$kernelsource\"" | wc -l` -eq 0 ]; then
    echo " "
    echo " VANIR BOTTLESERVICE. YOU KNOW HOW WE DO."
    echo " "
    echo " Adding a line for $device's kernel to .repo/local_manifests/bottleservice.xml,
    and adding another bottle of Crystal to your tab."
    echo " "
    pushd . >& /dev/null
    cd .repo/local_manifests
    cat bottleservice.xml | grep -v '</manifest>' > tmp.xml
    NEWLINE="<project path=\"$TARGET_KERNEL_SOURCE\" name=\"$kernelsource\""
    [ $remote ] && NEWLINE="$NEWLINE remote=\"$remote\""
    [ $remoterevision ] && NEWLINE="$NEWLINE revision=\"$remoterevision\""
    NEWLINE="$NEWLINE />"
    echo "  $NEWLINE" >> tmp.xml
    echo "</manifest>" >> tmp.xml
    mv tmp.xml bottleservice.xml
    echo " Added:  $NEWLINE to bottleservice.xml"
    echo " "
    echo " re-syncing!"
    popd >& /dev/null
    . build/envsetup.sh >& /dev/null
    reposync -c -f -j32 -q
    echo " "
    echo " re-sync complete"
fi
