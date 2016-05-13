#!/bin/bash 
#===============================================================================
#          FILE:  helper.sh
#         USAGE:  ./helper.sh -h
#   DESCRIPTION:  SugarCRM bash helper library for Linux
#       AUTHORS:  Nicolae V. CRISTEA;
#       LICENSE:  MIT
#===============================================================================

DIR="${BASH_SOURCE%/*}"
if [ ! -d "$DIR" ]; then DIR="$PWD"; fi
logFile=$DIR/log/day_$(date '+%Y-%m-%d').log
. "$DIR/app/lib.sh"
. "$DIR/app/cmd.sh"

usage() {
    cat <<EOM
$(secho "Usage:" yellow)
 $(basename $0) [-h] [option]

$(secho "Arguments:" yellow)
   option      Main menu option to execute

$(secho "Options:" yellow)
   -h          Display help usage
EOM
    exit 0
}

boot()
{
    OPT=""

    for conf in $(find "$DIR/config" -name '*.yml' -or -name '*.yaml')
    do
        # read .yml file
        if [[ "${conf}" != *"_private.yml"  ]]; then
            eval "$(parse_yaml ${conf} '_')"
        fi
    done

    if [ -f $DIR/config/_private.yml ]; then
        eval "$(parse_yaml $DIR/config/_private.yml '_')"
    fi

    subCmd $@
    draw _ 24 'menu'
    helperAlias
    menu "option" $1 $2
}

# parse the options
while getopts 'o:h' opt ; do
  case ${opt} in
    o)      OPT=$OPTARG ;;
    h)      usage ;;
    [?])	usage ;;
  esac
done
# skip over the processed options
shift $((OPTIND-1))

boot $@