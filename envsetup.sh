function hmm() {
cat <<EOF
Invoke ". build/envsetup.sh" from your shell to add the following functions to your environment:
- lunch:   lunch <product_name>-<build_variant>
- tapas:   tapas [<App1> <App2> ...] [arm|x86|mips|armv5] [eng|userdebug|user]
- croot:   Changes directory to the top of the tree.
- m:       Makes from the top of the tree.
- mm:      Builds all of the modules in the current directory.
- mmp:     Builds all of the modules in the current directory and pushes them to the device.
- mmm:     Builds all of the modules in the supplied directories.
- mmmp:    Builds all of the modules in the supplied directories and pushes them to the device.
- mma:     Builds all of the modules in the current directory, and their dependencies.
- mmma:    Builds all of the modules in the supplied directories, and their dependencies.
- mgrep:   Greps on all local .mk files.
- cgrep:   Greps on all local C/C++ files.
- jgrep:   Greps on all local Java files.
- resgrep: Greps on all local res/*.xml files.
- godir:   Go to the directory containing a file.
- mka:      Builds using SCHED_BATCH on all processors
- mkap:     Builds the module(s) using mka and pushes them to the device.
- cmka:     Cleans and builds using mka.
- cmkap:     Cleans and builds using mka, then crams it in your phone's gullet.
- reposync: Parallel repo sync using ionice and SCHED_BATCH
- smash:    clean out the out directory of your lunched target only.
- bashtest: Push a shell script to the phone and execute it.

Look at the source to view more functions. The complete list is:
EOF
    T=$(gettop)
    local A
    A=""
    for i in `cat $T/build/envsetup.sh | sed -n "/^function /s/function \([a-z_]*\).*/\1/p" | sort`; do
      A="$A $i"
    done
    echo $A
}

BLACK='\[\033[0;30m\]'
BLUE='\[\033[0;34m\]'
GREEN='\[\033[0;32m\]'
CYAN='\[\033[0;36m\]'
RED='\[\033[0;31m\]'
PURPLE='\[\033[0;35m\]'
BROWN='\[\033[0;33m\]'
LIGHTGREY='\[\033[0;37m\]'
DARKGREY='\[\033[1;30m\]'
LIGHTBLUE='\[\033[1;34m\]'
LIGHTGREEN='\[\033[1;32m\]'
LIGHTCYAN='\[\033[1;36m\]'
LIGHTRED='\[\033[1;31m\]'
LIGHTPURPLE='\[\033[1;35m\]'
YELLOW='\[\033[1;33m\]'
WHITE='\[\033[1;37m\]'
NONE='\[\033[0m\]'

#run a command inside all projects tracked on the vanir remote in the manifest
function forall_vanir()
{
  T=$(gettop)
  if [ ! "$T" ]; then
    echo "Couldn't locate the top of the tree.  Try setting TOP." >&2
    return
  fi
  local cmd
  local pathlist
  pushd . >& /dev/null
  cd $T
  pathlist=""
  for x in `cat $(gettop)/.repo/manifest.xml | grep \<project | sed 's/.*project //g' | grep 'remote=\"vanir\"' | sed 's/[ ]*\/*>//g' | sed 's/groups=[\"a-zA-Z0-9,\-]*//g' | sed 's/.*path="//g' | sed 's/\".*//g'`; do
    pathlist="$pathlist $x"
  done
  cmd="`echo $* | sed 's/\"/\\\"/g'`"
  repo forall $pathlist -c "eval $cmd"
  popd >& /dev/null
}

# Get the value of a build variable as an absolute path.
function get_abs_build_var()
{
    T=$(gettop)
    if [ ! "$T" ]; then
        echo "Couldn't locate the top of the tree.  Try setting TOP." >&2
        return
    fi
    (\cd $T; CALLED_FROM_SETUP=true BUILD_SYSTEM=build/core \
      make --no-print-directory -C "$T" -f build/core/config.mk dumpvar-abs-$1)
}

# Get the exact value of a build variable.
function get_build_var()
{
    T=$(gettop)
    if [ ! "$T" ]; then
        echo "Couldn't locate the top of the tree.  Try setting TOP." >&2
        return
    fi
    CALLED_FROM_SETUP=true BUILD_SYSTEM=build/core \
      make --no-print-directory -C "$T" -f build/core/config.mk dumpvar-$1
}

# check to see if the supplied product is one we can build
function check_product()
{
    T=$(gettop)
    if [ ! "$T" ]; then
        echo "Couldn't locate the top of the tree.  Try setting TOP." >&2
        return
    fi
    CALLED_FROM_SETUP=true BUILD_SYSTEM=build/core \
        TARGET_PRODUCT=$1 \
        TARGET_BUILD_VARIANT= \
        TARGET_BUILD_TYPE= \
        TARGET_BUILD_APPS= \
        get_build_var TARGET_DEVICE > /dev/null
    # hide successful answers, but allow the errors to show
}

VARIANT_CHOICES=(user userdebug eng)

# check to see if the supplied variant is valid
function check_variant()
{
    for v in ${VARIANT_CHOICES[@]}
    do
        if [ "$v" = "$1" ]
        then
            return 0
        fi
    done
    return 1
}

function setpaths()
{
    T=$(gettop)
    if [ ! "$T" ]; then
        echo "Couldn't locate the top of the tree.  Try setting TOP."
        return
    fi

    ##################################################################
    #                                                                #
    #              Read me before you modify this code               #
    #                                                                #
    #   This function sets ANDROID_BUILD_PATHS to what it is adding  #
    #   to PATH, and the next time it is run, it removes that from   #
    #   PATH.  This is required so lunch can be run more than once   #
    #   and still have working paths.                                #
    #                                                                #
    ##################################################################

    # Note: on windows/cygwin, ANDROID_BUILD_PATHS will contain spaces
    # due to "C:\Program Files" being in the path.

    # out with the old
    if [ -n "$ANDROID_BUILD_PATHS" ] ; then
        export PATH=${PATH/$ANDROID_BUILD_PATHS/}
    fi
    if [ -n "$ANDROID_PRE_BUILD_PATHS" ] ; then
        export PATH=${PATH/$ANDROID_PRE_BUILD_PATHS/}
        # strip leading ':', if any
        export PATH=${PATH/:%/}
    fi

    # and in with the new
    CODE_REVIEWS=
    prebuiltdir=$(getprebuilt)
    gccprebuiltdir=$(get_abs_build_var ANDROID_GCC_PREBUILTS)

    # defined in core/config.mk
    targetgccversion=$(get_build_var TARGET_GCC_VERSION)
    export TARGET_GCC_VERSION=$targetgccversion

    # The gcc toolchain does not exists for windows/cygwin. In this case, do not reference it.
    export ANDROID_EABI_TOOLCHAIN=
    local ARCH=$(get_build_var TARGET_ARCH)
    case $ARCH in
        x86) toolchaindir=x86/i686-linux-android-$targetgccversion/bin
            ;;

        arm) toolchaindir=arm/arm-linux-androideabi-$targetgccversion/bin

            ;;
        mips) toolchaindir=mips/mipsel-linux-android-$targetgccversion/bin
            ;;
        *)
            echo "Can't find toolchain for unknown architecture: $ARCH"
            toolchaindir=xxxxxxxxx
            ;;
    esac
    if [ -d "$gccprebuiltdir/$toolchaindir" ]; then
        export ANDROID_EABI_TOOLCHAIN=$gccprebuiltdir/$toolchaindir
    fi

    unset ARM_EABI_TOOLCHAIN ARM_EABI_TOOLCHAIN_PATH
    case $ARCH in
        arm)
            toolchaindir=arm/arm-eabi-$targetgccversion/bin
            if [ -d "$gccprebuiltdir/$toolchaindir" ]; then
                 export ARM_EABI_TOOLCHAIN="$gccprebuiltdir/$toolchaindir"
                 ARM_EABI_TOOLCHAIN_PATH=":$gccprebuiltdir/$toolchaindir"
            fi
            ;;
        mips) toolchaindir=mips/mips-eabi-4.4.3/bin
            ;;
        *)
             # No need to set ARM_EABI_TOOLCHAIN for other ARCHs
            ;;
    esac

    export ANDROID_TOOLCHAIN=$ANDROID_EABI_TOOLCHAIN
    export ANDROID_QTOOLS=$T/development/emulator/qtools
    export ANDROID_DEV_SCRIPTS=$T/development/scripts:$T/prebuilts/devtools/tools
    export ANDROID_BUILD_PATHS=:$(get_build_var ANDROID_BUILD_PATHS):$ANDROID_QTOOLS:$ANDROID_TOOLCHAIN$ARM_EABI_TOOLCHAIN_PATH$CODE_REVIEWS:$ANDROID_DEV_SCRIPTS
    export PATH=$PATH$ANDROID_BUILD_PATHS

    unset ANDROID_JAVA_TOOLCHAIN
    unset ANDROID_PRE_BUILD_PATHS
    if [ -n "$JAVA_HOME" ]; then
        export ANDROID_JAVA_TOOLCHAIN=$JAVA_HOME/bin
        export ANDROID_PRE_BUILD_PATHS=$ANDROID_JAVA_TOOLCHAIN:
        export PATH=$ANDROID_PRE_BUILD_PATHS$PATH
    fi

    unset ANDROID_PRODUCT_OUT
    export ANDROID_PRODUCT_OUT=$(get_abs_build_var PRODUCT_OUT)
    export OUT=$ANDROID_PRODUCT_OUT

    unset ANDROID_HOST_OUT
    export ANDROID_HOST_OUT=$(get_abs_build_var HOST_OUT)

    # needed for processing samples collected by perf counters
    unset OPROFILE_EVENTS_DIR
    export OPROFILE_EVENTS_DIR=$T/external/oprofile/events

    # needed for building linux on MacOS
    # TODO: fix the path
    #export HOST_EXTRACFLAGS="-I "$T/system/kernel_headers/host_include
}

function printconfig()
{
    T=$(gettop)
    if [ ! "$T" ]; then
        echo "Couldn't locate the top of the tree.  Try setting TOP." >&2
        return
    fi
    get_build_var report_config
}

function set_stuff_for_environment()
{
    settitle
    set_java_home
    setpaths
    set_sequence_number
}

function set_sequence_number()
{
    export BUILD_ENV_SEQUENCE_NUMBER=10
}

function settitle()
{
    if [ "$STAY_OFF_MY_LAWN" = "" ]; then
        local arch=$(gettargetarch)
        local product=$TARGET_PRODUCT
        local variant=$TARGET_BUILD_VARIANT
        local apps=$TARGET_BUILD_APPS
        if [ -z "$PROMPT_COMMAND"  ]; then
            # No prompts
            PROMPT_COMMAND="echo -ne \"\033]0;${USER}@${HOSTNAME}: ${PWD}\007\""
        elif [ -z "$(echo $PROMPT_COMMAND | grep '033]0;')" ]; then
            # Prompts exist, but no hardstatus
            PROMPT_COMMAND="echo -ne \"\033]0;${USER}@${HOSTNAME}: ${PWD}\007\";${PROMPT_COMMAND}"
        fi
        if [ ! -z "$ANDROID_PROMPT_PREFIX" ]; then
            PROMPT_COMMAND="$(echo $PROMPT_COMMAND | sed -e 's/$ANDROID_PROMPT_PREFIX //g')"
        fi

        if [ -z "$apps" ]; then
            ANDROID_PROMPT_PREFIX="[${arch}-${product}-${variant}]"
        else
            ANDROID_PROMPT_PREFIX="[$arch $apps $variant]"
        fi
        export ANDROID_PROMPT_PREFIX

        # Inject build data into hardstatus
        export PROMPT_COMMAND="$(echo $PROMPT_COMMAND | sed -e 's/\\033]0;\(.*\)\\007/\\033]0;$ANDROID_PROMPT_PREFIX \1\\007/g')"
    fi
}

function check_bash_version()
{
    # Keep us from trying to run in something that isn't bash.
    if [ -z "${BASH_VERSION}" ]; then
        return 1
    fi

    # Keep us from trying to run in bash that's too old.
    if [ "${BASH_VERSINFO[0]}" -lt 4 ] ; then
        return 2
    fi

    return 0
}

function choosetype()
{
    echo "Build type choices are:"
    echo "     1. release"
    echo "     2. debug"
    echo

    local DEFAULT_NUM DEFAULT_VALUE
    DEFAULT_NUM=1
    DEFAULT_VALUE=release

    export TARGET_BUILD_TYPE=
    local ANSWER
    while [ -z $TARGET_BUILD_TYPE ]
    do
        echo -n "Which would you like? ["$DEFAULT_NUM"] "
        if [ -z "$1" ] ; then
            read ANSWER
        else
            echo $1
            ANSWER=$1
        fi
        case $ANSWER in
        "")
            export TARGET_BUILD_TYPE=$DEFAULT_VALUE
            ;;
        1)
            export TARGET_BUILD_TYPE=release
            ;;
        release)
            export TARGET_BUILD_TYPE=release
            ;;
        2)
            export TARGET_BUILD_TYPE=debug
            ;;
        debug)
            export TARGET_BUILD_TYPE=debug
            ;;
        *)
            echo
            echo "I didn't understand your response.  Please try again."
            echo
            ;;
        esac
        if [ -n "$1" ] ; then
            break
        fi
    done

    set_stuff_for_environment
}

#
# This function isn't really right:  It chooses a TARGET_PRODUCT
# based on the list of boards.  Usually, that gets you something
# that kinda works with a generic product, but really, you should
# pick a product by name.
#
function chooseproduct()
{
    if [ "x$TARGET_PRODUCT" != x ] ; then
        default_value=$TARGET_PRODUCT
    else
        default_value=full
    fi

    export TARGET_PRODUCT=
    local ANSWER
    while [ -z "$TARGET_PRODUCT" ]
    do
        echo -n "Which product would you like? [$default_value] "
        if [ -z "$1" ] ; then
            read ANSWER
        else
            echo $1
            ANSWER=$1
        fi

        if [ -z "$ANSWER" ] ; then
            export TARGET_PRODUCT=$default_value
        else
            if check_product $ANSWER
            then
                export TARGET_PRODUCT=$ANSWER
            else
                echo "** Not a valid product: $ANSWER"
            fi
        fi
        if [ -n "$1" ] ; then
            break
        fi
    done

    set_stuff_for_environment
}

function choosevariant()
{
    echo "Variant choices are:"
    local index=1
    local v
    for v in ${VARIANT_CHOICES[@]}
    do
        # The product name is the name of the directory containing
        # the makefile we found, above.
        echo "     $index. $v"
        index=$(($index+1))
    done

    local default_value=eng
    local ANSWER

    export TARGET_BUILD_VARIANT=
    while [ -z "$TARGET_BUILD_VARIANT" ]
    do
        echo -n "Which would you like? [$default_value] "
        if [ -z "$1" ] ; then
            read ANSWER
        else
            echo $1
            ANSWER=$1
        fi

        if [ -z "$ANSWER" ] ; then
            export TARGET_BUILD_VARIANT=$default_value
        elif (echo -n $ANSWER | grep -q -e "^[0-9][0-9]*$") ; then
            if [ "$ANSWER" -le "${#VARIANT_CHOICES[@]}" ] ; then
                export TARGET_BUILD_VARIANT=${VARIANT_CHOICES[$(($ANSWER-1))]}
            fi
        else
            if check_variant $ANSWER
            then
                export TARGET_BUILD_VARIANT=$ANSWER
            else
                echo "** Not a valid variant: $ANSWER"
            fi
        fi
        if [ -n "$1" ] ; then
            break
        fi
    done
}

function choosecombo()
{
    choosetype $1

    echo
    echo
    chooseproduct $2

    echo
    echo
    choosevariant $3

    echo
    set_stuff_for_environment
    printconfig
}

# Clear this variable.  It will be built up again when the vendorsetup.sh
# files are included at the end of this file.
unset LUNCH_MENU_CHOICES
function add_lunch_combo()
{
    local new_combo=$1
    local c
    for c in ${LUNCH_MENU_CHOICES[@]} ; do
        if [ "$new_combo" = "$c" ] ; then
            return
        fi
    done
    LUNCH_MENU_CHOICES=(${LUNCH_MENU_CHOICES[@]} $new_combo)
}

# add the default one here
add_lunch_combo aosp_arm-eng
add_lunch_combo aosp_x86-eng
add_lunch_combo aosp_mips-eng
add_lunch_combo vbox_x86-eng

function print_lunch_menu()
{
    local uname=$(uname)
    echo
    echo "You're building on" $uname
    echo
    echo "Lunch menu... pick a combo:"

    local i=1
    local choice
    for choice in ${LUNCH_MENU_CHOICES[@]}
    do
        echo " $i. $choice "
        i=$(($i+1))
    done | column

    echo
}

function lunch()
{
    local answer

    if [ "$1" ] ; then
        answer=$1
    else
        print_lunch_menu
        echo -n "Which would you like? [aosp_arm-eng] "
        read answer
    fi

    local selection=

    if [ -z "$answer" ]
    then
        selection=aosp_arm-eng
    elif (echo -n $answer | grep -q -e "^[0-9][0-9]*$")
    then
        if [ $answer -le ${#LUNCH_MENU_CHOICES[@]} ]
        then
            selection=${LUNCH_MENU_CHOICES[$(($answer-1))]}
        fi
    elif (echo -n $answer | grep -q -e "^[^\-][^\-]*-[^\-][^\-]*$")
    then
        selection=$answer
    fi

    if [ -z "$selection" ]
    then
        echo
        echo "Invalid lunch combo: $answer"
        return 1
    fi

    export TARGET_BUILD_APPS=

    local product=$(echo -n $selection | sed -e "s/-.*$//")
    check_product $product    
    if [ $? -ne 0 ]
    then
        echo
        echo "** Don't have a product spec for: '$product'"
        echo "** Do you have the right repo manifest?"
        product=
    fi
    local variant=$(echo -n $selection | sed -e "s/^[^\-]*-//")
    check_variant $variant
    if [ $? -ne 0 ]
    then
        echo
        echo "** Invalid variant: '$variant'"
        echo "** Must be one of ${VARIANT_CHOICES[@]}"
        variant=
    fi

    if [ -z "$product" -o -z "$variant" ]
    then
        echo
        return 1
    fi
    T=$(gettop)
    if [ $T ]; then
        pushd . >& /dev/null
        cd $T
        build/tools/bottleservice.sh $product || return 1
        popd >& /dev/null
    fi

    export TARGET_PRODUCT=$product
    export TARGET_BUILD_VARIANT=$variant
    export TARGET_BUILD_TYPE=release

    echo

    fixup_common_out_dir

    set_stuff_for_environment
    printconfig
}

# Tab completion for lunch.
function _lunch()
{
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    COMPREPLY=( $(compgen -W "${LUNCH_MENU_CHOICES[*]}" -- ${cur}) )
    return 0
}
complete -F _lunch lunch

# Configures the build to build unbundled apps.
# Run tapas with one ore more app names (from LOCAL_PACKAGE_NAME)
function tapas()
{
    local arch=$(echo -n $(echo $* | xargs -n 1 echo | \grep -E '^(arm|x86|mips|armv5)$'))
    local variant=$(echo -n $(echo $* | xargs -n 1 echo | \grep -E '^(user|userdebug|eng)$'))
    local apps=$(echo -n $(echo $* | xargs -n 1 echo | \grep -E -v '^(user|userdebug|eng|arm|x86|mips|armv5)$'))

    if [ $(echo $arch | wc -w) -gt 1 ]; then
        echo "tapas: Error: Multiple build archs supplied: $arch"
        return
    fi
    if [ $(echo $variant | wc -w) -gt 1 ]; then
        echo "tapas: Error: Multiple build variants supplied: $variant"
        return
    fi

    local product=full
    case $arch in
      x86)   product=full_x86;;
      mips)  product=full_mips;;
      armv5) product=generic_armv5;;
    esac
    if [ -z "$variant" ]; then
        variant=eng
    fi
    if [ -z "$apps" ]; then
        apps=all
    fi

    export TARGET_PRODUCT=$product
    export TARGET_BUILD_VARIANT=$variant
    export TARGET_BUILD_TYPE=release
    export TARGET_BUILD_APPS=$apps

    set_stuff_for_environment
    printconfig
}

function gettop
{
    local TOPFILE=build/core/envsetup.mk
    if [ -n "$TOP" -a -f "$TOP/$TOPFILE" ] ; then
        echo $TOP
    else
        if [ -f $TOPFILE ] ; then
            # The following circumlocution (repeated below as well) ensures
            # that we record the true directory name and not one that is
            # faked up with symlink names.
            PWD= /bin/pwd
        else
            local HERE=$PWD
            T=
            while [ \( ! \( -f $TOPFILE \) \) -a \( $PWD != "/" \) ]; do
                \cd ..
                T=`PWD= /bin/pwd`
            done
            \cd $HERE
            if [ -f "$T/$TOPFILE" ]; then
                echo $T
            fi
        fi
    fi
}

function m()
{
    T=$(gettop)
    if [ "$T" ]; then
        make -C $T -f build/core/main.mk $@
    else
        echo "Couldn't locate the top of the tree.  Try setting TOP."
    fi
}

function findmakefile()
{
    TOPFILE=build/core/envsetup.mk
    local HERE=$PWD
    T=
    while [ \( ! \( -f $TOPFILE \) \) -a \( $PWD != "/" \) ]; do
        T=`PWD= /bin/pwd`
        if [ -f "$T/Android.mk" ]; then
            echo $T/Android.mk
            \cd $HERE
            return
        fi
        \cd ..
    done
    \cd $HERE
}

function mm()
{
    local MM_MAKE=make
    local ARG=
    for ARG in $@ ; do
        if [ "$ARG" = mka ]; then
            MM_MAKE=mka
        fi
    done
    # If we're sitting in the root of the build tree, just do a
    # normal make.
    if [ -f build/core/envsetup.mk -a -f Makefile ]; then
        $MM_MAKE $@
    else
        # Find the closest Android.mk file.
        T=$(gettop)
        local M=$(findmakefile)
        local MODULES=
        local GET_INSTALL_PATH=
        local ARGS=
        # Remove the path to top as the makefilepath needs to be relative
        local M=`echo $M|sed 's:'$T'/::'`
        if [ ! "$T" ]; then
            echo "Couldn't locate the top of the tree.  Try setting TOP."
        elif [ ! "$M" ]; then
            echo "Couldn't locate a makefile from the current directory."
        else
            for ARG in $@; do
                case $ARG in
                  GET-INSTALL-PATH) GET_INSTALL_PATH=$ARG;;
                esac
            done
            if [ -n "$GET_INSTALL_PATH" ]; then
              MODULES=
              ARGS=GET-INSTALL-PATH
            else
              MODULES=all_modules
              ARGS=$@
            fi
            ONE_SHOT_MAKEFILE=$M make -C $T -f build/core/main.mk $MODULES $ARGS
        fi
    fi
}

function mmm()
{
    local MMM_MAKE=make
    T=$(gettop)
    if [ "$T" ]; then
        local MAKEFILE=
        local MODULES=
        local ARGS=
        local DIR TO_CHOP
        local GET_INSTALL_PATH=
        local DASH_ARGS=$(echo "$@" | awk -v RS=" " -v ORS=" " '/^-.*$/')
        local DIRS=$(echo "$@" | awk -v RS=" " -v ORS=" " '/^[^-].*$/')
        for DIR in $DIRS ; do
            MODULES=`echo $DIR | sed -n -e 's/.*:\(.*$\)/\1/p' | sed 's/,/ /'`
            if [ "$MODULES" = "" ]; then
                MODULES=all_modules
            fi
            DIR=`echo $DIR | sed -e 's/:.*//' -e 's:/$::'`
            if [ -f $DIR/Android.mk ]; then
                local TO_CHOP=`(\cd -P -- $T && pwd -P) | wc -c | tr -d ' '`
                local TO_CHOP=`expr $TO_CHOP + 1`
                local START=`PWD= /bin/pwd`
                local MFILE=`echo $START | cut -c${TO_CHOP}-`
                if [ "$MFILE" = "" ] ; then
                    MFILE=$DIR/Android.mk
                else
                    MFILE=$MFILE/$DIR/Android.mk
                fi
                MAKEFILE="$MAKEFILE $MFILE"
            else
                case $DIR in
                  showcommands | snod | dist | incrementaljavac) ARGS="$ARGS $DIR";;
                  GET-INSTALL-PATH) GET_INSTALL_PATH=$DIR;;
                  *) echo "No Android.mk in $DIR."; return 1;;
                esac
            fi
        done
        if [ -n "$GET_INSTALL_PATH" ]; then
          ARGS=$GET_INSTALL_PATH
          MODULES=
        fi
        ONE_SHOT_MAKEFILE="$MAKEFILE" make -C $T -f build/core/main.mk $DASH_ARGS $MODULES $ARGS
    else
        echo "Couldn't locate the top of the tree.  Try setting TOP."
    fi
}

function mma()
{
  if [ -f build/core/envsetup.mk -a -f Makefile ]; then
    make $@
  else
    T=$(gettop)
    if [ ! "$T" ]; then
      echo "Couldn't locate the top of the tree.  Try setting TOP."
    fi
    local MY_PWD=`PWD= /bin/pwd|sed 's:'$T'/::'`
    make -C $T -f build/core/main.mk $@ all_modules BUILD_MODULES_IN_PATHS="$MY_PWD"
  fi
}

function mmma()
{
  T=$(gettop)
  if [ "$T" ]; then
    local DASH_ARGS=$(echo "$@" | awk -v RS=" " -v ORS=" " '/^-.*$/')
    local DIRS=$(echo "$@" | awk -v RS=" " -v ORS=" " '/^[^-].*$/')
    local MY_PWD=`PWD= /bin/pwd`
    if [ "$MY_PWD" = "$T" ]; then
      MY_PWD=
    else
      MY_PWD=`echo $MY_PWD|sed 's:'$T'/::'`
    fi
    local DIR=
    local MODULE_PATHS=
    local ARGS=
    for DIR in $DIRS ; do
      if [ -d $DIR ]; then
        if [ "$MY_PWD" = "" ]; then
          MODULE_PATHS="$MODULE_PATHS $DIR"
        else
          MODULE_PATHS="$MODULE_PATHS $MY_PWD/$DIR"
        fi
      else
        case $DIR in
          showcommands | snod | dist | incrementaljavac) ARGS="$ARGS $DIR";;
          *) echo "Couldn't find directory $DIR"; return 1;;
        esac
      fi
    done
    make -C $T -f build/core/main.mk $DASH_ARGS $ARGS all_modules BUILD_MODULES_IN_PATHS="$MODULE_PATHS"
  else
    echo "Couldn't locate the top of the tree.  Try setting TOP."
  fi
}

function croot()
{
    T=$(gettop)
    if [ "$T" ]; then
        \cd $(gettop)
    else
        echo "Couldn't locate the top of the tree.  Try setting TOP."
    fi
}

function cproj()
{
    TOPFILE=build/core/envsetup.mk
    local HERE=$PWD
    T=
    while [ \( ! \( -f $TOPFILE \) \) -a \( $PWD != "/" \) ]; do
        T=$PWD
        if [ -f "$T/Android.mk" ]; then
            \cd $T
            return
        fi
        \cd ..
    done
    \cd $HERE
    echo "can't find Android.mk"
}

# simplified version of ps; output in the form
# <pid> <procname>
function qpid() {
    local prepend=''
    local append=''
    if [ "$1" = "--exact" ]; then
        prepend=' '
        append='$'
        shift
    elif [ "$1" = "--help" -o "$1" = "-h" ]; then
		echo "usage: qpid [[--exact] <process name|pid>"
		return 255
	fi

    local EXE="$1"
    if [ "$EXE" ] ; then
		qpid | \grep "$prepend$EXE$append"
	else
		adb shell ps \
			| tr -d '\r' \
			| sed -e 1d -e 's/^[^ ]* *\([0-9]*\).* \([^ ]*\)$/\1 \2/'
	fi
}

function pid()
{
    local prepend=''
    local append=''
    if [ "$1" = "--exact" ]; then
        prepend=' '
        append='$'
        shift
    fi
    local EXE="$1"
    if [ "$EXE" ] ; then
        local PID=`adb shell ps \
            | tr -d '\r' \
            | \grep "$prepend$EXE$append" \
            | sed -e 's/^[^ ]* *\([0-9]*\).*$/\1/'`
        echo "$PID"
    else
        echo "usage: pid [--exact] <process name>"
		return 255
    fi
}

# systemstack - dump the current stack trace of all threads in the system process
# to the usual ANR traces file
function systemstack()
{
    stacks system_server
}

function stacks()
{
    if [[ $1 =~ ^[0-9]+$ ]] ; then
        local PID="$1"
    elif [ "$1" ] ; then
        local PIDLIST="$(pid $1)"
        if [[ $PIDLIST =~ ^[0-9]+$ ]] ; then
            local PID="$PIDLIST"
        elif [ "$PIDLIST" ] ; then
            echo "more than one process: $1"
        else
            echo "no such process: $1"
        fi
    else
        echo "usage: stacks [pid|process name]"
    fi

    if [ "$PID" ] ; then
        # Determine whether the process is native
        if adb shell ls -l /proc/$PID/exe | grep -q /system/bin/app_process ; then
            # Dump stacks of Dalvik process
            local TRACES=/data/anr/traces.txt
            local ORIG=/data/anr/traces.orig
            local TMP=/data/anr/traces.tmp

            # Keep original traces to avoid clobbering
            adb shell mv $TRACES $ORIG

            # Make sure we have a usable file
            adb shell touch $TRACES
            adb shell chmod 666 $TRACES

            # Dump stacks and wait for dump to finish
            adb shell kill -3 $PID
            adb shell notify $TRACES >/dev/null

            # Restore original stacks, and show current output
            adb shell mv $TRACES $TMP
            adb shell mv $ORIG $TRACES
            adb shell cat $TMP
        else
            # Dump stacks of native process
            adb shell debuggerd -b $PID
        fi
    fi
}

function gdbwrapper()
{
    $ANDROID_TOOLCHAIN/$GDB -x "$@"
}

function gdbclient()
{
   local OUT_ROOT=$(get_abs_build_var PRODUCT_OUT)
   local OUT_SYMBOLS=$(get_abs_build_var TARGET_OUT_UNSTRIPPED)
   local OUT_SO_SYMBOLS=$(get_abs_build_var TARGET_OUT_SHARED_LIBRARIES_UNSTRIPPED)
   local OUT_EXE_SYMBOLS=$(get_abs_build_var TARGET_OUT_EXECUTABLES_UNSTRIPPED)
   local PREBUILTS=$(get_abs_build_var ANDROID_PREBUILTS)
   local ARCH=$(get_build_var TARGET_ARCH)
   local GDB
   case "$ARCH" in
       x86) GDB=i686-linux-android-gdb;;
       arm) GDB=arm-linux-androideabi-gdb;;
       mips) GDB=mipsel-linux-android-gdb;;
       *) echo "Unknown arch $ARCH"; return 1;;
   esac

   if [ "$OUT_ROOT" -a "$PREBUILTS" ]; then
       local EXE="$1"
       if [ "$EXE" ] ; then
           EXE=$1
       else
           EXE="app_process"
       fi

       local PORT="$2"
       if [ "$PORT" ] ; then
           PORT=$2
       else
           PORT=":5039"
       fi

       local PID="$3"
       if [ "$PID" ] ; then
           if [[ ! "$PID" =~ ^[0-9]+$ ]] ; then
               PID=`pid $3`
               if [[ ! "$PID" =~ ^[0-9]+$ ]] ; then
                   # that likely didn't work because of returning multiple processes
                   # try again, filtering by root processes (don't contain colon)
                   PID=`adb shell ps | \grep $3 | \grep -v ":" | awk '{print $2}'`
                   if [[ ! "$PID" =~ ^[0-9]+$ ]]
                   then
                       echo "Couldn't resolve '$3' to single PID"
                       return 1
                   else
                       echo ""
                       echo "WARNING: multiple processes matching '$3' observed, using root process"
                       echo ""
                   fi
               fi
           fi
           adb forward "tcp$PORT" "tcp$PORT"
           adb shell gdbserver $PORT --attach $PID &
           sleep 2
       else
               echo ""
               echo "If you haven't done so already, do this first on the device:"
               echo "    gdbserver $PORT /system/bin/$EXE"
                   echo " or"
               echo "    gdbserver $PORT --attach <PID>"
               echo ""
       fi

       echo >|"$OUT_ROOT/gdbclient.cmds" "set solib-absolute-prefix $OUT_SYMBOLS"
       echo >>"$OUT_ROOT/gdbclient.cmds" "set solib-search-path $OUT_SO_SYMBOLS:$OUT_SO_SYMBOLS/hw:$OUT_SO_SYMBOLS/ssl/engines:$OUT_SO_SYMBOLS/drm:$OUT_SO_SYMBOLS/egl:$OUT_SO_SYMBOLS/soundfx"
       echo >>"$OUT_ROOT/gdbclient.cmds" "source $ANDROID_BUILD_TOP/development/scripts/gdb/dalvik.gdb"
       echo >>"$OUT_ROOT/gdbclient.cmds" "target remote $PORT"
       echo >>"$OUT_ROOT/gdbclient.cmds" ""

       gdbwrapper "$OUT_ROOT/gdbclient.cmds" "$OUT_EXE_SYMBOLS/$EXE"
  else
       echo "Unable to determine build system output dir."
   fi

}

case `uname -s` in
    Darwin)
        function sgrep()
        {
            find -E . -name .repo -prune -o -name .git -prune -o  -type f -iregex '.*\.(c|h|cpp|S|java|xml|sh|mk)' -print0 | xargs -0 grep --color -n "$@"
        }

        ;;
    *)
        function sgrep()
        {
            find . -name .repo -prune -o -name .git -prune -o  -type f -iregex '.*\.\(c\|h\|cpp\|S\|java\|xml\|sh\|mk\)' -print0 | xargs -0 grep --color -n "$@"
        }
        ;;
esac

function gettargetarch
{
    get_build_var TARGET_ARCH
}

function jgrep()
{
    find . -name .repo -prune -o -name .git -prune -o  -type f -name "*\.java" -print0 | xargs -0 grep --color -n "$@"
}

function cgrep()
{
    find . -name .repo -prune -o -name .git -prune -o -type f \( -name '*.c' -o -name '*.cc' -o -name '*.cpp' -o -name '*.h' \) -print0 | xargs -0 grep --color -n "$@"
}

function resgrep()
{
    #if we're in a subdir of res, than don't try to find a res directory below us.
    [ `pwd | grep '/res' | wc -l` -gt 0 ] && find . -type f -name '*\.xml' -print0 | xargs -0 grep --color -n "$@" && return 0
    
    #if not, assume it's below our folder
    foundone=
    for dir in `find . -name .repo -prune -o -name .git -prune -o -name res -type d`; do find $dir -type f -name '*\.xml' -print0 | xargs -0 grep --color -n "$@"; done;
    [ ! -z $foundone ] && return 0

    #if res isn't our parent, and we're not in a parent of res, then res is probably our uncle.
    pushd . >& /dev/null
    T=$(gettop)
    reldir=""
    while [ 1 ]; do
        if [ -d res ]; then
            popd >& /dev/null
            find ${reldir}res -type f -name '*\.xml' -print0 | xargs -0 grep --color -n "$@"
            foundone=1
            return 0
        elif [ "`pwd`" = "$T" ] || [ "`pwd`" = "/" ]; then
            foundone=1
            popd >& /dev/null
            return 1
        fi
        reldir="$reldir../"
        cd ..
    done
}

function mangrep()
{
    find . -name .repo -prune -o -name .git -prune -o -path ./out -prune -o -type f -name 'AndroidManifest.xml' -print0 | xargs -0 grep --color -n "$@"
}

function sepgrep()
{
    find . -name .repo -prune -o -name .git -prune -o -path ./out -prune -o -name sepolicy -type d -print0 | xargs -0 grep --color -n -r --exclude-dir=\.git "$@"
}

case `uname -s` in
    Darwin)
        function mgrep()
        {
            find -E . -name .repo -prune -o -name .git -prune -o -path ./out -prune -o -type f -iregex '.*/(Makefile|Makefile\..*|.*\.make|.*\.mak|.*\.mk)' -print0 | xargs -0 grep --color -n "$@"
        }

        function treegrep()
        {
            find -E . -name .repo -prune -o -name .git -prune -o -type f -iregex '.*\.(c|h|cpp|S|java|xml)' -print0 | xargs -0 grep --color -n -i "$@"
        }

        ;;
    *)
        function mgrep()
        {
            find . -name .repo -prune -o -name .git -prune -o -path ./out -prune -o -regextype posix-egrep -iregex '(.*\/Makefile|.*\/Makefile\..*|.*\.make|.*\.mak|.*\.mk)' -type f -print0 | xargs -0 grep --color -n "$@"
        }

        function treegrep()
        {
            find . -name .repo -prune -o -name .git -prune -o -regextype posix-egrep -iregex '.*\.(c|h|cpp|S|java|xml)' -type f -print0 | xargs -0 grep --color -n -i "$@"
        }

        ;;
esac

function getprebuilt
{
    get_abs_build_var ANDROID_PREBUILTS
}

function tracedmdump()
{
    T=$(gettop)
    if [ ! "$T" ]; then
        echo "Couldn't locate the top of the tree.  Try setting TOP."
        return
    fi
    local prebuiltdir=$(getprebuilt)
    local arch=$(gettargetarch)
    local KERNEL=$T/prebuilts/qemu-kernel/$arch/vmlinux-qemu

    local TRACE=$1
    if [ ! "$TRACE" ] ; then
        echo "usage:  tracedmdump  tracename"
        return
    fi

    if [ ! -r "$KERNEL" ] ; then
        echo "Error: cannot find kernel: '$KERNEL'"
        return
    fi

    local BASETRACE=$(basename $TRACE)
    if [ "$BASETRACE" = "$TRACE" ] ; then
        TRACE=$ANDROID_PRODUCT_OUT/traces/$TRACE
    fi

    echo "post-processing traces..."
    rm -f $TRACE/qtrace.dexlist
    post_trace $TRACE
    if [ $? -ne 0 ]; then
        echo "***"
        echo "*** Error: malformed trace.  Did you remember to exit the emulator?"
        echo "***"
        return
    fi
    echo "generating dexlist output..."
    /bin/ls $ANDROID_PRODUCT_OUT/system/framework/*.jar $ANDROID_PRODUCT_OUT/system/app/*.apk $ANDROID_PRODUCT_OUT/data/app/*.apk 2>/dev/null | xargs dexlist > $TRACE/qtrace.dexlist
    echo "generating dmtrace data..."
    q2dm -r $ANDROID_PRODUCT_OUT/symbols $TRACE $KERNEL $TRACE/dmtrace || return
    echo "generating html file..."
    dmtracedump -h $TRACE/dmtrace >| $TRACE/dmtrace.html || return
    echo "done, see $TRACE/dmtrace.html for details"
    echo "or run:"
    echo "    traceview $TRACE/dmtrace"
}

# communicate with a running device or emulator, set up necessary state,
# and run the hat command.
function runhat()
{
    # process standard adb options
    local adbTarget=""
    if [ "$1" = "-d" -o "$1" = "-e" ]; then
        adbTarget=$1
        shift 1
    elif [ "$1" = "-s" ]; then
        adbTarget="$1 $2"
        shift 2
    fi
    local adbOptions=${adbTarget}
    #echo adbOptions = ${adbOptions}

    # runhat options
    local targetPid=$1

    if [ "$targetPid" = "" ]; then
        echo "Usage: runhat [ -d | -e | -s serial ] target-pid"
        return
    fi

    # confirm hat is available
    if [ -z $(which hat) ]; then
        echo "hat is not available in this configuration."
        return
    fi

    # issue "am" command to cause the hprof dump
    local sdcard=$(adb ${adbOptions} shell echo -n '$EXTERNAL_STORAGE')
    local devFile=$sdcard/hprof-$targetPid
    #local devFile=/data/local/hprof-$targetPid
    echo "Poking $targetPid and waiting for data..."
    echo "Storing data at $devFile"
    adb ${adbOptions} shell am dumpheap $targetPid $devFile
    echo "Press enter when logcat shows \"hprof: heap dump completed\""
    echo -n "> "
    read

    local localFile=/tmp/$$-hprof

    echo "Retrieving file $devFile..."
    adb ${adbOptions} pull $devFile $localFile

    adb ${adbOptions} shell rm $devFile

    echo "Running hat on $localFile"
    echo "View the output by pointing your browser at http://localhost:7000/"
    echo ""
    hat -JXmx512m $localFile
}

function getbugreports()
{
    local reports=(`adb shell ls /sdcard/bugreports | tr -d '\r'`)

    if [ ! "$reports" ]; then
        echo "Could not locate any bugreports."
        return
    fi

    local report
    for report in ${reports[@]}
    do
        echo "/sdcard/bugreports/${report}"
        adb pull /sdcard/bugreports/${report} ${report}
        gunzip ${report}
    done
}

function getsdcardpath()
{
    adb ${adbOptions} shell echo -n \$\{EXTERNAL_STORAGE\}
}

function getscreenshotpath()
{
    echo "$(getsdcardpath)/Pictures/Screenshots"
}

function getlastscreenshot()
{
    local screenshot_path=$(getscreenshotpath)
    local screenshot=`adb ${adbOptions} ls ${screenshot_path} | grep Screenshot_[0-9-]*.*\.png | sort -rk 3 | cut -d " " -f 4 | head -n 1`
    if [ "$screenshot" = "" ]; then
        echo "No screenshots found."
        return
    fi
    echo "${screenshot}"
    adb ${adbOptions} pull ${screenshot_path}/${screenshot}
}

function startviewserver()
{
    local port=4939
    if [ $# -gt 0 ]; then
            port=$1
    fi
    adb shell service call window 1 i32 $port
}

function stopviewserver()
{
    adb shell service call window 2
}

function isviewserverstarted()
{
    adb shell service call window 3
}

function key_home()
{
    adb shell input keyevent 3
}

function key_back()
{
    adb shell input keyevent 4
}

function key_menu()
{
    adb shell input keyevent 82
}

function smoketest()
{
    if [ ! "$ANDROID_PRODUCT_OUT" ]; then
        echo "Couldn't locate output files.  Try running 'lunch' first." >&2
        return
    fi
    T=$(gettop)
    if [ ! "$T" ]; then
        echo "Couldn't locate the top of the tree.  Try setting TOP." >&2
        return
    fi

    (\cd "$T" && mmm tests/SmokeTest) &&
      adb uninstall com.android.smoketest > /dev/null &&
      adb uninstall com.android.smoketest.tests > /dev/null &&
      adb install $ANDROID_PRODUCT_OUT/data/app/SmokeTestApp.apk &&
      adb install $ANDROID_PRODUCT_OUT/data/app/SmokeTest.apk &&
      adb shell am instrument -w com.android.smoketest.tests/android.test.InstrumentationTestRunner
}

# simple shortcut to the runtest command
function runtest()
{
    T=$(gettop)
    if [ ! "$T" ]; then
        echo "Couldn't locate the top of the tree.  Try setting TOP." >&2
        return
    fi
    ("$T"/development/testrunner/runtest.py $@)
}

function godir () {
    if [[ -z "$1" ]]; then
        echo "Usage: godir <regex>"
        return
    fi
    T=$(gettop)
    if [[ ! -f $T/filelist ]]; then
        echo -n "Creating index..."
        (\cd $T; find . -wholename ./out -prune -o -wholename ./.repo -prune -o -type f > filelist)
        echo " Done"
        echo ""
    fi
    local lines
    lines=($(\grep "$1" $T/filelist | sed -e 's/\/[^/]*$//' | sort | uniq))
    if [[ ${#lines[@]} = 0 ]]; then
        echo "Not found"
        return
    fi
    local pathname
    local choice
    if [[ ${#lines[@]} > 1 ]]; then
        while [[ -z "$pathname" ]]; do
            local index=1
            local line
            for line in ${lines[@]}; do
                printf "%6s %s\n" "[$index]" $line
                index=$(($index + 1))
            done
            echo
            echo -n "Select one: "
            unset choice
            read choice
            if [[ $choice -gt ${#lines[@]} || $choice -lt 1 ]]; then
                echo "Invalid choice"
                continue
            fi
            pathname=${lines[$(($choice-1))]}
        done
    else
        pathname=${lines[0]}
    fi
    \cd $T/$pathname
}

function linaroinit()
{
    pushd . >& /dev/null
    cd $(gettop)
    if [ ! -e .ccache_cleaned_for_gcc48 ]; then
        if [ `uname -a | grep -i darwin | wc -l` -eq 0 ]; then
            export PATH=$PATH:`pwd`/prebuilts/misc/linux-x86/ccache/
        else
            export PATH=$PATH:`pwd`/prebuilts/misc/darwin-x86/ccache/
        fi
        echo "Clearing your ccache in preparation for your first build with GCC 4.8"
        echo "(preprocessed files from ccache and gcc4.7 aren't compatible with gcc4.8 compilation,"
        echo "   so your ccache needs to be restarted from scratch)"
        ccache -C -z && touch .ccache_cleaned_for_gcc48
    fi
    if [ ! -e .nukewazhere ]; then
        rm -rf build-info android-toolchain-eabi android-toolchain-eabi-gcc4.8-turboexperimental .nukesballs .nukesballs48 .usinggcc48
        touch .nukewazhere
        UBUNTU=`cat /etc/issue.net | cut -d' ' -f2`
        HOST_ARCH=`uname -m`
        echo "HOST_ARCH = ${HOST_ARCH}"
        if [ ${HOST_ARCH} == "x86_64" ] ; then
               PKGS='git-core gnupg flex bison gperf build-essential zip curl zlib1g-dev libc6-dev lib32ncurses5-dev x11proto-core-dev libx11-dev lib32z1-dev libgl1-mesa-dev g++-multilib mingw32 tofrodos python-markdown libxml2-utils xsltproc uboot-mkimage openjdk-6-jdk openjdk-6-jre vim-common'
        else
               echo "ERROR: Only 64bit Host(Build) machines are supported at the moment."
               exit 1
        fi

        PKGS+=' lib32readline-gplv2-dev'
        echo "If you're not on ubuntu 12.04, this might not work."

        echo "Checking and installing missing dependencies if any .. .."
        sudo apt-get install ${PKGS}

        MISSING=`dpkg-query -W -f='${Status}\n' ${PKGS} 2>&1 | grep 'No packages found matching' | cut -d' ' -f5`
        if [ -n "$MISSING" ] ; then
               echo "Missing required packages:"
               for m in $MISSING ; do
                       echo -n "${m%?} "
               done
               echo
               return 1
        fi
    fi
    popd >& /dev/null
    return 0
}


function mka() {
T=$(gettop)
if [ ! "$T" ]; then
    echo "Couldn't locate the top of the tree.  CD into it, or try setting TOP." >&2
    return
fi
linaroinit
export TARGET_SIMULATOR=false
export BUILD_TINY_ANDROID=
retval=0
    case `uname -s` in
        Darwin)
            local threads=`sysctl hw.ncpu|cut -d" " -f2`
            local load=`expr $threads \* 2`
            time make -j $load "$@"
            retval=$?
            ;;
        *)
            local threads=`grep "^processor" /proc/cpuinfo | wc -l`
            local load=`expr $threads \* 2`
            time schedtool -B -n 1 -e ionice -n 1 make -j $load "$@"
            retval=$?
            ;;
    esac
if [ $retval -eq 0 ]; then
    notify-send "VANIR" "$TARGET_PRODUCT build completed." -i $T/build/buildwin.png -t 10000
else
    notify-send "VANIR" "$TARGET_PRODUCT build FAILED." -i $T/build/buildfailed.png -t 10000
fi
return $retval
}

function mkc() {
pathpat="^.*:[0-9]+"
ccred=$(echo -e "\033[1;31m")
ccyellow=$(echo -e "\033[1;33m")
ccend=$(echo -e "\033[0m")
echo -e "$ccyellow BUILDING $ccred WITH $ccyellow COLORED $ccred WARNINGS $ccred AND $ccyellow STUFF$ccend"
mka "$@" 2>&1 | sed -E -e "/[Ee]rror[: ]/ s%$pathpat%$ccred&$ccend%g" -e "/[Ww]arning[: ]/ s%$pathpat%$ccyellow&$ccend%g"
return ${PIPESTATUS[0]}
}


function cmka() {
    if [ ! -z "$1" ]; then
        for i in "$@"; do
            case $i in
                bacon|otapackage|systemimage)
                    mka installclean
                    mka $i
                    ;;
                *)
                    mka clean-$i
                    mka $i
                    ;;
            esac
        done
    else
        mka clean
        mka
    fi
}

# Credit for color strip sed: http://goo.gl/BoIcm
function dopush()
{
    local func=$1
    shift

    adb start-server # Prevent unexpected starting server message from adb get-state in the next line
    if [ $(adb get-state) != device -a $(adb shell busybox test -e /sbin/recovery 2> /dev/null; echo $?) != 0 ] ; then
        echo "No device is online. Waiting for one..."
        echo "Please connect USB and/or enable USB debugging"
        until [ $(adb get-state) = device -o $(adb shell busybox test -e /sbin/recovery 2> /dev/null; echo $?) = 0 ];do
            sleep 1
        done
        echo "Device Found."
    fi

    if (adb shell cat /system/build.prop | grep -q "ro.product.device=vanir_$TARGET_PRODUCT");
    then
    adb root &> /dev/null
    sleep 0.3
    adb wait-for-device &> /dev/null
    sleep 0.3
    adb remount &> /dev/null

    $func $* | tee $OUT/.log

    # Install: <file>
    LOC=$(cat $OUT/.log | sed -r 's/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g' | grep 'Install' | cut -d ':' -f 2)

    # Copy: <file>
    LOC=$LOC $(cat $OUT/.log | sed -r 's/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g' | grep 'Copy' | cut -d ':' -f 2)

    for FILE in $LOC; do
        # Get target file name (i.e. system/bin/adb)
        TARGET=$(echo $FILE | sed "s#$OUT/##")

        # Don't send files that are not in /system.
        if ! echo $TARGET | egrep '^system\/' > /dev/null ; then
            continue
        else
            case $TARGET in
            system/app/SystemUI.apk|system/framework/*)
                stop_n_start=true
            ;;
            *)
                stop_n_start=false
            ;;
            esac
            if $stop_n_start ; then adb shell stop ; fi
            echo "Pushing: $TARGET"
            adb push $FILE $TARGET
            if $stop_n_start ; then adb shell start ; fi
        fi
    done
    rm -f $OUT/.log
    return 0
    else
        echo "The connected device does not appear to be $TARGET_PRODUCT, run away!"
    fi
}

alias mmp='dopush mm'
alias mmmp='dopush mmm'
alias mkap='dopush mka'
alias cmkap='dopush cmka'

smash() {
#to do: add smash $anytarget, smashOTA, smash, smashVANIR
DIR=$OUT
#to do: fix the colors
	if [ -d  "$DIR" ]; then
	echo ""
	echo $CL_RED" Removing" $CL_RST" $TARGET_PRODUCT out directory:"
	echo " Location:"
	echo " $OUT"
	rm -R -f $OUT
	echo "  ."
	echo "  ."
	echo "  ."
	echo "  ."
	echo "  ."
	echo $CL_RST" Destroyed."
	echo ""
	return;
	else 
	echo ""
	echo $CL_YLW" Already" $CL_RED" SMASHED it !!!" $CL_RST
	echo ""
	fi
}

bashtest() {
    if [ -z "$1" ]; then
        echo "Usage:  bashtest <relative path to shell script> [(optional) destination dir]"
        return 0
    fi
    local srcpath="$1"
    local destpath="/cache/"
    destpath=`echo $destpath | sed 's/\/$//g'`
    local binname="`basename $srcpath`"
    if [ ! -z "$2" ]; then 
        destpath="$2"
    fi
    adb start-server # Prevent unexpected starting server message from adb get-state in the next line
    if [ $(adb get-state) != device -a $(adb shell busybox test -e /sbin/recovery 2> /dev/null; echo $?) != 0 ] ; then
        echo "No device is online. Waiting for one..."
        echo "Please connect USB and/or enable USB debugging"
        until [ $(adb get-state) = device -o $(adb shell busybox test -e /sbin/recovery 2> /dev/null; echo $?) = 0 ];do
            sleep 1
        done
        echo "Device Found."
    fi
    echo
    echo "Pushing $srcpath to $destpath and running it as root!"
    echo
    adb push $srcpath /sdcard/$binname >& /dev/null
    adb root >& /dev/null
    (adb shell "cp /sdcard/$binname $destpath/$binname; rm /sdcard/$binname; chmod 755 $destpath/$binname") >& /dev/null
    adb shell sh $destpath/$binname
}

function reposync() {
    case `uname -s` in
        Darwin)
            repo sync -j 4 "$@"
            ;;
        *)
            schedtool -B -n 1 -e ionice -n 1 repo sync -j 4 "$@"
            ;;
    esac
}

function fixup_common_out_dir() {
    common_out_dir=$(get_build_var OUT_DIR)/target/common
    target_device=$(get_build_var TARGET_DEVICE)
    if [ ! -z $CM_FIXUP_COMMON_OUT ]; then
        if [ -d ${common_out_dir} ] && [ ! -L ${common_out_dir} ]; then
            mv ${common_out_dir} ${common_out_dir}-${target_device}
            ln -s ${common_out_dir}-${target_device} ${common_out_dir}
        else
            [ -L ${common_out_dir} ] && rm ${common_out_dir}
            mkdir -p ${common_out_dir}-${target_device}
            ln -s ${common_out_dir}-${target_device} ${common_out_dir}
        fi
    else
        [ -L ${common_out_dir} ] && rm ${common_out_dir}
        mkdir -p ${common_out_dir}
    fi
}

# Force JAVA_HOME to point to java 1.6 if it isn't already set
function set_java_home() {
    if [ ! "$JAVA_HOME" ]; then
        case `uname -s` in
            Darwin)
                export JAVA_HOME=/System/Library/Frameworks/JavaVM.framework/Versions/1.6/Home
                ;;
            *)
                export JAVA_HOME=/usr/lib/jvm/java-6-sun
                ;;
        esac
    fi
}

# Print colored exit condition
function pez {
    "$@"
    local retval=$?
    if [ $retval -ne 0 ]
    then
        echo -e "\e[0;31mFAILURE\e[00m"
    else
        echo -e "\e[0;32mSUCCESS\e[00m"
    fi
    return $retval
}

if [ "x$SHELL" != "x/bin/bash" ]; then
    case `ps -o command -p $$` in
        *bash*)
            ;;
        *)
            echo "WARNING: Only bash is supported, use of other shell would lead to erroneous results"
            ;;
    esac
fi

# Execute the contents of any vendorsetup.sh files we can find.
for f in `test -d device && find device -maxdepth 4 -name 'vendorsetup.sh' 2> /dev/null` \
         `test -d vendor && find vendor -maxdepth 4 -name 'vendorsetup.sh' 2> /dev/null`
do
    echo "including $f"
    . $f
done
unset f

# Add completions
check_bash_version && {
    dirs="sdk/bash_completion vendor/cm/bash_completion"
    for dir in $dirs; do
    if [ -d ${dir} ]; then
        for f in `/bin/ls ${dir}/[a-z]*.bash 2> /dev/null`; do
            echo "including $f"
            . $f
        done
    fi
    done
}

# SWITCH TO A VERSION OF REPO THAT DOESN'T SPAM PROJECT NAMES
pushd . >& /dev/null
cd $(gettop)/.repo/repo
[ `git remote -v | grep vanir | wc -l` -eq 0 ] && git remote add vanir http://www.emccann.net/repo
git fetch vanir >& /dev/null
git checkout vanir/master >& /dev/null
popd >& /dev/null

#rst (repo start helper), rup (repo upload helper)
source $(gettop)/build/nukehawtness

parse_git_dirty() {
 [[ $(git status 2> /dev/null | tail -n1) != "nothing to commit (working directory clean)" ]] && echo " \*"
}
parse_git_branch() {     
 [ "$(parse_git_dirty)" = "" ] && echo -en "\033[1;32m" || echo -en "\033[1;31m"
 git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e "s/* \(.*\)/ (\1$(parse_git_dirty))/"
}
if [ ! $GITPS1ENGAGED ]; then
export GITPS1ENGAGED=1
export PS1=`echo "$PS1" | sed 's/\[\$ \]*//g'`
istheregit=$(which git)
if [ `echo $PS1 | grep parse_git_branch | wc -l` -eq 0 ]; then
  if [ -x "$istheregit" ]; then
      export PS1="${NONE}$PS1\$(parse_git_branch)${NONE}"
  else
      export PS1="$PS1$ "
  fi
  export PS1=`echo "$PS1" | sed 's/$[ ]*$//g'`"\n${NONE}\$ "
fi
fi

#allow tab completion of git commands and branch names
if [ `typeset -F | grep _git | wc -l` -eq 0 ]; then
    source $(gettop)/build/git-completion.bash
fi
export ANDROID_BUILD_TOP=$(gettop)
