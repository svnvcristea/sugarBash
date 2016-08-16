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

        'installInstance')
            setYmlVal "_nusim_sugar_db_key" 'dbKey'
            local cmd="nusim install:developer -e dev --license-key ${_nusim_sugar_license} --repo-path ${_nusim_sugar_mango}"
            cmd="${cmd} --instance ${_nusim_sugar_name} --sugar-version ${_nusim_sugar_version} --sugar-flavor=${_nusim_sugar_flavor}"
            cmd="${cmd} --admin-user-name ${_nusim_sugar_admin_user} --admin-password ${_nusim_sugar_admin_pass}"

            if [ ${dbKey} == 'oracle' ]; then
                cmd="${cmd} --db-type ${_db_oracle_type} --db-user ${_db_oracle_connect_user} --db-pass ${_db_oracle_connect_pass}"
                cmd="${cmd} --db-host ${_db_oracle_connect_host} --db-port ${_db_oracle_port} --db-name ${_db_oracle_setRoot_host}/orcl"
            else
                cmd="${cmd} --db-type ${_db_mysql_type} --db-user ${_db_mysql_connect_user} --db-pass ${_db_mysql_connect_pass}"
                cmd="${cmd} --db-host ${_db_mysql_connect_host} --db-port ${_db_mysql_port} --db-name turbinado"
            fi
            secho "${cmd}" 'menu'
            ${cmd} &
            ssudo 'tail -f /tmp/nusim/nusim.log'
            local localIpCmd="ip -f inet addr show eth1 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*'"
            local ipVal=$(eval "${localIpCmd}")
            secho "http://${ipVal}/${_nusim_sugar_name}/${_nusim_sugar_flavor}" 'green'
        ;;

        'fullTest')
            secho 'ToDO!' 'red'
        ;;

        *)
			break
        ;;
    esac

    drawOptionDone
}
