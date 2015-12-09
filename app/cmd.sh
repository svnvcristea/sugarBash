#!/usr/bin/env bash
#===============================================================================
#          FILE:  cmd.sh
#         USAGE:  ./helper.sh -h
#   DESCRIPTION:  SugarCRM bash helper library for Linux
#       AUTHORS:  Nicolae V. CRISTEA;
#       LICENSE:  MIT
#===============================================================================

subCmd()
{
    if [ ! -z "${1}" ] && [ -z "${1##*[!0-9]*}" ]; then
        showTitle "${1} ${2} ${3}"
        $1 $2 $3
        drawOptionDone
        exit 1
    fi
}

von()
{
   local stack=${2}
   if [ -z ${stack} ]; then
        stack="php54"
    fi

    if [ $1 == "halt" ] || [ $1 == "suspend" ]; then
        mountFstab ${stack} umount
    fi

    setYamlVal "_von_path"
    cd ${ymlVal}
    vagrant $1 $2

    if [ $1 == "up" ]; then
        mountFstab ${stack}
    fi
}
