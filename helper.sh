#!/bin/bash 

boot()
{
    DIR="${BASH_SOURCE%/*}"
    if [ ! -d "$DIR" ]; then DIR="$PWD"; fi
    . "$DIR/lib.sh"
    OPT=""
    # read yaml file
    eval $(parse_yaml config.yml "_")

    menu
}

boot