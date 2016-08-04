#!/bin/bash
#===============================================================================
#          FILE:  nusim.sh
#         USAGE:  ./helper.sh -h
#   DESCRIPTION:  SugarCRM bash helper library for Linux
#       AUTHORS:  Nicolae V. CRISTEA;
#       LICENSE:  MIT
#===============================================================================

newsim()
{
    secho "# nusim: $@" 'menu'

    case ${1} in
        'check')
            nusim list
			which nusim
            nusim -V
        ;;

        'install')
            setYmlVal "_nusim_tmppath" 'gitRepoPath'
            setYmlVal "_git_GitHub_nusim" 'nusimRepo'
            rm -rf ${gitRepoPath}
            mkdir -p ${gitRepoPath}
            ssudo "rm /usr/local/bin/nusim"
            secho "# git clone ${nusimRepo} ${gitRepoPath}" 'menu'
            cd ${gitRepoPath}
            git clone ${nusimRepo} ./ -b develop
            composer install
            secho "# install nusim" 'menu'
            ssudo "php bin/nusim self:compile -e dev -i -v"
            nusim --list
            nusim -V
        ;;

        'fullTest')
            nusim
        ;;

        *)
			break
        ;;
    esac

    drawOptionDone
}
