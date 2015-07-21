#!/bin/bash
if [ "`which automake``which autogen`" = "" ]; then
  echo "automake or autogen is required to build ccache and was not found." 1>&2
  if [ "`which apt-get`" != "" ]; then
    echo "INSTALLING AUTOMAKE. You will now be asked to approve sudo" 1>&2
    sudo bash -c "apt-get install -y --force-yes automake 1>&2"
  else
    for x in {1..10}; do
      echo "As you don't have apt-get, you must install automake or autogen manually" 1>&2
    done
    exit 1
  fi
fi

if [ -e ./ccache/ccache ] && grep $(./ccache/ccache -V | grep "ccache version" | awk '{print $3}') ccache/version.c 2>&1 >/dev/null; then
    # ccache exists and its --version output matches the latest source
    echo "ccache is up to date" 1>&2
else
    echo "building ccache binary" 1>&2
    pushd ccache 2>&1 >/dev/null
    ./autogen.sh 1>&2
    ./configure 1>&2
    make 1>&2
    popd 2>&1 >/dev/null
    echo "ccache updated to version `ccache/ccache -V`" 1>&2
fi
mkdir -p `pwd`/.ccachesymlinks
$(dirname $0)/update-ccache-symlinks `pwd`/.ccachesymlinks
