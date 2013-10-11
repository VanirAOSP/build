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

[ $remote ] && [ "$remote" = "cm" ] && export remote=

if [ ! -e .repo/local_manifests ] || [ ! -e .repo/local_manifests/bottleservice.xml ]; then
    mkdir -p .repo/local_manifests
    echo '<?xml version="1.0" encoding="UTF-8"?>
<manifest>
</manifest>' > .repo/local_manifests/bottleservice.xml
fi
if [ `cat .repo/local_manifests/bottleservice.xml | egrep "path=\"$TARGET_KERNEL_SOURCE\"" | wc -l` -gt 1 ]; then
   echo "UH OH! You have duplicate repos for $TARGET_KERNEL_SOURCE in bottleservice.xml"
   echo "Let's pick one arbitrarily and get rid of the rest."
   line=`cat .repo/local_manifests/bottleservice.xml | egrep "path=\"$TARGET_KERNEL_SOURCE\"" | head -n 1`
   cat .repo/local_manifests/bottleservice.xml | grep -v "</manifest>" | egrep -v "path=\"$TARGET_KERNEL_SOURCE\"" > .repo/local_manifests/tmp.xml
   echo "$line" >> .repo/local_manifests/tmp.xml
   echo "</manifest>" >> .repo/local_manifests/tmp.xml
   mv .repo/local_manifests/tmp.xml .repo/local_manifests/bottleservice.xml
fi
getkernelline='path="'$TARGET_KERNEL_SOURCE'" name="'$kernelsource'"'
[ $remote ] && getkernelline=$getkernelline' remote="'$remote'"'
[ $remoterevision ] && getkernelline=$getkernelline' revision="'$remoterevision'"'
haskernelline=`cat .repo/local_manifests/bottleservice.xml | egrep "$getkernelline" | wc -l`
hasdevice=`cat .repo/local_manifests/bottleservice.xml | egrep "<!-- $device -->" | wc -l`
if [ $hasdevice -gt 0 ] && [ $haskernelline -eq 0 ]; then
   #device comment is in the file, but its kernel is the wrong one
   line=`cat .repo/local_manifests/bottleservice.xml | egrep "<!-- $device -->"`
   cat .repo/local_manifests/bottleservice.xml | egrep -v "$line" > .repo/local_manifests/tmp.xml
   remainingdevs=""
   echo "removing $device from previous kernel line: $line"
   for x in `echo $line | sed 's/.*\/> //g' | sed 's/<!-- //g' | sed 's/ -->/ /g'`; do
       if [ ! "$device" = $x ]; then
           remainingdevs="$remainingdevs<!-- $x -->"
       fi
   done
   echo "remaining line that used to have device = $line"
   if [ `echo $remainingdevs | wc -c` -gt 1 ]; then
       echo "`echo "$line" | sed 's/<!--.*//g'`$remainingdevs" >> .repo/local_manifests/tmp.xml
   fi
   echo "</manifest>" >> .repo/local_manifests/tmp.xml
   mv .repo/local_manifests/tmp.xml .repo/local_manifests/bottleservice.xml
elif [ $haskernelline -gt 0 ] && [ $hasdevice -eq 0 ]; then
    #device's kernel is in the file, but device comment isn't added yet
    line=`cat .repo/local_manifests/bottleservice.xml | egrep "$getkernelline"`
    echo "Adding $device to already existing kernel line: $line"
    cat .repo/local_manifests/bottleservice.xml | egrep -v "$line" | grep -v "</manifest>" > .repo/local_manifests/tmp.xml
    echo "$line <!-- $device -->" >> .repo/local_manifests/tmp.xml
    echo "</manifest>" >> .repo/local_manifests/tmp.xml
    mv .repo/local_manifests/tmp.xml .repo/local_manifests/bottleservice.xml
fi
if [ $haskernelline -eq 0 ]; then
    #add kernel to the file
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
    NEWLINE="$NEWLINE /> <!-- $device -->"
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
exit 0
