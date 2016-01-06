#!/bin/bash

get_source_ccache_version()
{
   version=`git --git-dir=./ccache/.git describe --dirty 2>/dev/null || echo unknown`
   if echo $version | grep -q "^v"; then
     version="`echo $version | sed 's/v//'`"
   fi
   echo $version | sed -e 's/-/+/' -e 's/-/_/g'
}

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
current_version="`get_source_ccache_version`"
if [ -e ./ccache/ccache ] && echo $current_version | grep -q $(./ccache/ccache -V | grep "ccache version" | awk '{print $3}'); then
    # ccache exists and its --version output matches the latest source
    echo "ccache is up to date" 1>&2
else
    set -e
    echo "building ccache binary" 1>&2
    pushd ccache 2>&1 >/dev/null
    ./autogen.sh >/dev/null
    ./configure >/dev/null
    make >/dev/null
    popd 2>&1 >/dev/null
    set +e
    echo "ccache updated to version $current_version" 1>&2
fi
