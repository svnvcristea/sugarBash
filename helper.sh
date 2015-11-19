#!/bin/bash 
#===============================================================================
#          FILE:  helper.sh
#         USAGE:  ./helper.sh -h
#   DESCRIPTION:  SugarCRM bash helper library for Linux
#       AUTHORS:  Nicolae V. CRISTEA;
#       VERSION:  0.9.0
#===============================================================================

DIR="${BASH_SOURCE%/*}"
if [ ! -d "$DIR" ]; then DIR="$PWD"; fi
. "$DIR/lib.sh"

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
    # read yaml file
    eval $(parse_yaml "$DIR/config.yml" "_")
    draw _ 24 'menu'
    helperAlias
    menu "option" $1
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

boot $1