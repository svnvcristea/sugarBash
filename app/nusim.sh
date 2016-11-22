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
    local title="# nusim: $@"
    secho "${title}" 'menu'
    startTime=$(date '+%Y-%m-%d %H:%M');
    secho "${startTime}" 'green'
    sleepUnit=3
    local scope="ps"
    if [ ! -z $2 ]; then
        scope="core"
    fi

    case ${1} in
        'check')
            nusim list
			which nusim
            nusim -V
        ;;

        'install')
            unixInstall git
            unixInstall composer

            local gitRepoPath="${_nusim_tmppath}/repo"
            rm -rf ${gitRepoPath}/nusim
            mkdir -p ${gitRepoPath}
            cd ${gitRepoPath}
            ssudo "rm /usr/local/bin/nusim"
            secho "# git clone ${_git_GitHub_nusim} ${gitRepoPath}" 'menu'
            git clone -b develop --recursive ${_git_GitHub_nusim} ./nusim
            cd nusim
            composer install
            ssudo "touch ${_nusim_tmppath}/nusim.log"
            ssudo "chmod 777 ${_nusim_tmppath}/nusim.log"
            secho "* install nusim" 'menu'
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
                cmd="${cmd} --db-host ${_db_mysql_connect_host} --db-port ${_db_mysql_port} --db-name ${_nusim_sugar_name,,}"
            fi
            tailPidCmd "${cmd}" '/tmp/nusim/nusim.log'

            wait $cmdPID
            sleep $sleepUnit
            secho "nusim command finished" 'menu'
            local localIpCmd="ip -f inet addr show eth1 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*'"
            local ipVal=$(eval "${localIpCmd}")
            secho "http://${ipVal}/${_nusim_sugar_name}/${_nusim_sugar_flavor}" 'green'
        ;;

        'createInstallPack')
            local dockerImageName="build_core_${_nusim_build_number}"
            if [ "${_nusim_build_with_nomad}" == 'true' ]; then
                gitCloneOrUpdate ${_git_GitHub_nomad} ${_nusim_tmppath}/repo nomad ${_nusim_build_branch_nomad} ${_nusim_build_checkout_nomad}
            fi
            gitCloneOrUpdate ${_git_GitHub_translations} ${_nusim_tmppath}/repo translations ${_nusim_build_branch_translations} ${_nusim_build_checkout_translations}
            gitCloneOrUpdate ${_git_GitHub_refinery} ${_nusim_tmppath}/repo refinery ${_nusim_build_branch_refinery} ${_nusim_build_checkout_refinery}

            cd ${_nusim_sugar_mango}
            gitMango postCheckout

            local cmd="nusim package:create:${scope}:install -e dev --mango-path ${_nusim_sugar_mango}"
            if [ "${_nusim_build_with_nomad}" == 'true' ]; then
                cmd="${cmd} --nomad-path=${_nusim_tmppath}/repo/nomad"
            fi
            cmd="${cmd} --translations-path ${_nusim_tmppath}/repo/translations"
            cmd="${cmd} --refinery-path ${_nusim_tmppath}/repo/refinery"
            cmd="${cmd} --build-path ${_nusim_tmppath}/builds/${_nusim_build_number}"
            cmd="${cmd} --build-number ${_nusim_build_number}"
            cmd="${cmd} --sugar-version ${_nusim_sugar_version}"
            cmd="${cmd} --config-version ${_nusim_build_configversion}"
            cmd="${cmd} --sugar-flavor ${_nusim_sugar_flavor}"
            if [ "${_nusim_build_with_translations}" == 'false' ]; then
                cmd="${cmd} --no-latin"
            fi
            if [ "$ME" == 'vagrant' ]; then
                cmd="echo \"${cmd}\" | sudo su -"
            fi

            nusim -V
            tailPidCmd "${cmd}" '/tmp/nusim/nusim.log'

            local sleepCount=0
            while [ -z "$(docker ps -a | grep build_core_)" -a $sleepCount -lt 300 ]; do
                sleep $sleepUnit
                let sleepCount=sleepCount+sleepUnit
            done

            if [ ${_nusim_log_docker} == "true" ]; then
                cmd="docker logs -f ${dockerImageName}"
                if [ "$ME" == 'vagrant' ]; then
                    secho "echo '${cmd} &' | sudo su -" 'menu'
                    echo "${cmd}" | sudo su -
                else
                    secho "${cmd}" 'menu'
                    ${cmd}
                fi
            fi

            wait $cmdPID
            sleep $sleepUnit
            secho "nusim command finished" 'menu'

            nusimZipBuild ${_nusim_build_number}
            nusimCpFullBuild ${_nusim_build_number}

            secho "/** Finished Create Install Pack **/" 'menu'
        ;;

        'createUpgradePack')
            local dockerImageName="build_core_${_nusim_build_upgrade_number}"
            local pathToBaseBuildPack="${_nusim_tmppath}/builds/${_nusim_build_number}"

            if [ "${_nusim_build_with_nomad}" == 'true' ]; then
                gitCloneOrUpdate ${_git_GitHub_nomad} ${_nusim_tmppath}/repo nomad ${_nusim_build_branch_nomad} ${_nusim_build_checkout_nomad}
            fi
            gitCloneOrUpdate ${_git_GitHub_translations} ${_nusim_tmppath}/repo translations ${_nusim_build_branch_translations} ${_nusim_build_checkout_translations}
            gitCloneOrUpdate ${_git_GitHub_refinery} ${_nusim_tmppath}/repo refinery ${_nusim_build_branch_refinery} ${_nusim_build_checkout_refinery}

            cd ${_nusim_sugar_mango}
            gitMango postCheckout

            local cmd="nusim package:create:ps:upgrade -e dev"
            cmd="${cmd} --mango-path ${_nusim_sugar_mango}"
            cmd="${cmd} --baseline-path ${pathToBaseBuildPack}"
            if [ "${_nusim_build_with_nomad}" == 'true' ]; then
                cmd="${cmd} --nomad-path=${_nusim_tmppath}/repo/nomad"
            fi
            cmd="${cmd} --translations-path ${_nusim_tmppath}/repo/translations"
            cmd="${cmd} --refinery-path ${_nusim_tmppath}/repo/refinery"
            cmd="${cmd} --build-path ${_nusim_tmppath}/builds/${_nusim_build_upgrade_number}"
            cmd="${cmd} --build-number ${_nusim_build_upgrade_number}"
            cmd="${cmd} --sugar-version ${_nusim_sugar_version} "
            cmd="${cmd} --config-version ${_nusim_build_configversion}"
            cmd="${cmd} --sugar-flavor ${_nusim_sugar_flavor}"
            if [ "$ME" == 'vagrant' ]; then
                cmd="echo \"${cmd}\" | sudo su -"
            fi

            nusim -V
            tailPidCmd "${cmd}" '/tmp/nusim/nusim.log'

            local sleepCount=0
            while [ -z "$(docker ps -a | grep build_core_)" -a $sleepCount -lt 300 ]; do
                sleep $sleepUnit
                let sleepCount=sleepCount+sleepUnit
            done

            if [ ${_nusim_log_docker} == "true" ]; then
                cmd="docker logs -f ${dockerImageName}"
                if [ "$ME" == 'vagrant' ]; then
                    secho "echo '${cmd} &' | sudo su -" 'menu'
                    echo "${cmd}" | sudo su -
                else
                    secho "${cmd}" 'menu'
                    ${cmd}
                fi
            fi

            wait $cmdPID
            sleep $sleepUnit
            secho "nusim command finished" 'menu'

            nusimZipBuild ${_nusim_build_upgrade_number}
            nusimCpFullBuild ${_nusim_build_upgrade_number}

            secho "/** Finished Create Upgrade Pack **/" 'menu'
        ;;

        'deployInstallPack')
            local cmd="nusim package:deploy:${scope}:install -e dev"
#            local installPack=$(ls ${_nusim_tmppath}/builds/refinery/${_nusim_build_number} | grep -oP "^[Sa-z]*.[\.|0-9]*.zip$")

            cmd="${cmd} --package-zip ${_nusim_tmppath}/builds/zip/${_nusim_build_number}.zip"
            cmd="${cmd} --relative-path ${_nusim_build_number}${_nusim_sugar_name}"
            cmd="${cmd} --db-user ${_nusim_sugar_db_user} --db-pass ${_nusim_sugar_db_pass}"

            if [ ${_nusim_sugar_db_key} == 'oracle' ]; then
                sqlPlusCreateUser ${_nusim_sugar_db_user} ${_nusim_sugar_db_pass}
                cmd="${cmd} --db-type ${_db_oracle_type} --db-name ${_db_oracle_setRoot_host}/orcl"
                cmd="${cmd} --db-host ${_db_oracle_connect_host} --db-port ${_db_oracle_port}"
            else
                cmd="${cmd} --db-type ${_db_mysql_type} --db-name ${_nusim_sugar_name,,}_${_nusim_build_number}"
                cmd="${cmd} --db-host ${_db_mysql_connect_host} --db-port ${_db_mysql_port}"
            fi
            cmd="${cmd} --license-key ${_nusim_sugar_license}"

            if [ "$ME" == 'vagrant' ]; then
                cmd="echo \"${cmd}\" | sudo su -"
            fi

            nusim -V
            tailPidCmd "${cmd}" '/tmp/nusim/nusim.log'
            wait $cmdPID
            sleep $sleepUnit
            secho "nusim command finished" 'menu'
        ;;

        'deployUpgradePack')
            local cmd="nusim package:deploy:${scope}:upgrade -e dev --relative-path ${_nusim_build_number}${_nusim_sugar_name}"
            cmd="${cmd} --package-zip ${_nusim_tmppath}/builds/zip/${_nusim_build_upgrade_to}.zip"

            if [ "$ME" == 'vagrant' ]; then
                cmd="echo \"${cmd}\" | sudo su -"
            fi

            nusim -V
            tailPidCmd "${cmd}" '/tmp/nusim/nusim.log'
            wait $cmdPID
            sleep $sleepUnit
        ;;

        'fullTest')
            secho 'ToDO!' 'red'
        ;;

        *)
			break
        ;;
    esac

    timeSpentSince "$startTime"
    drawOptionDone
}

nusimZipBuild() {
    cd ${_nusim_tmppath}/builds/${1}
    zip -rq ${1}.zip ./
    mkdir -p ${_nusim_tmppath}/builds/zip
    mv ${1}.zip ${_nusim_tmppath}/builds/zip
    ls ${_nusim_tmppath}/builds/zip/${1}.zip
}

nusimCpFullBuild() {
    mkdir -p ${_nusim_tmppath}/builds/refinery/${1}
    cp ${_nusim_tmppath}/repo/refinery/build/* ${_nusim_tmppath}/builds/refinery/${1}
    secho "ls -la ${_nusim_tmppath}/builds/refinery/${1}" 'menu'
    ls -la ${_nusim_tmppath}/builds/refinery/${1}
}
