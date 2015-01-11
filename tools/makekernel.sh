#!/bin/bash
###############################################################################
## A simple build tool to compile the kernel from the custom rom source root ##
## The output file is located in the TARGET_DEVICE product /out directory    ##
## named $(TARGET_DEVICE)_kernel.zip                                         ##
##                                                                           ##
## Dave Kessler <activethrasher00@gmail.com>                                 ##
## github: AlmightyMegadeth00                                                ##
## Written for Vanir-Exodus 1/10/15                                          ##
##                                                                           ##
###############################################################################

DATE_START=$(date +"%s")

CL_YLW="\033[33m"
CL_RST="\033[0m"
CL_RED="\033[31m"

# Inherited build variables
DEVICE=$1
TOOLCHAIN=$2
TARGET_KERNEL_SOURCE=$3
TARGET_KERNEL_CONFIG=$4

# Output directory for lunched device
T=$PWD
OUT=$T/out/target/product/$DEVICE

cd $T/$TARGET_KERNEL_SOURCE

echo ""
echo -e $CL_RST"Cleaning up..."
#make clean; sleep 3; make distclean; sleep 3;
#rm -rfv .config; rm -rfv .config.old

echo ""
echo ""
echo -e $CL_RST"Compiling..."
sed -i s/CONFIG_LOCALVERSION=\".*\"/CONFIG_LOCALVERSION=\"~${DEVICE}_kernel\"/ arch/arm/configs/$TARGET_KERNEL_CONFIG

local cores=`nproc --all`
SET_CORES="-j$cores"

# TO DO: make toolchain location var more flexible
make CROSS_COMPILE=$TOOLCHAIN/arm-eabi- ARCH=arm $TARGET_KERNEL_CONFIG
make CROSS_COMPILE=$TOOLCHAIN/arm-eabi- ARCH=arm $SET_CORES

echo ""
echo ""
echo -e $CL_YLW"======================================="
echo -e $CL_RST"   Kernel compilation completed ... "
echo -e $CL_RST"   ... creating a flashable zip file"
echo -e $CL_YLW"======================================="
echo ""

cd $T/$TARGET_KERNEL_SOURCE

zipfile="${DEVICE}_kernel.zip"
if [ ! $5 ]; then
    rm -f /tmp/*.img
    echo -e $CL_RST"making zip file"
    cp -vr arch/arm/boot/zImage $T/build/tools/AnyKernel/
    find . -name \*.ko -exec cp '{}' AnyKernel/system/lib/modules/ ';'
    cd build/tools/AnyKernel
            rm -f *.zip
            zip -r $zipfile *
            rm -f /tmp/*.zip
            cp *.zip /$OUT
fi

if [[ $1 == *exp* ]]; then
    if [[ $1 == *bm* ]]; then
            mf="44latestbigmem"
    else
            mf="44latestexp"
    fi
else
    mf="44latest"
fi

cd $T; cd $TARGET_KERNEL_SOURCE

echo ""
echo $CL_YLW"=================================================================================="
echo ""
DATE_END=$(date +"%s")
DIFF=$(($DATE_END - $DATE_START))
echo -e $CL_YLW"Kernel build:" $CL_RED"completed" $CL_RST"in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
echo ""
echo -e $CL_YLW"Zip file location:"
echo -e $CL_RST"$OUT/$zipfile"
