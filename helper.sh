#!/bin/bash 

boot()
{
    DIR="${BASH_SOURCE%/*}"
    if [ ! -d "$DIR" ]; then DIR="$PWD"; fi
    . "$DIR/lib.sh"
    OPT=""
    # read yaml file
    eval $(parse_yaml "$DIR/config.yml" "_")
    menu $1
}

boot $1