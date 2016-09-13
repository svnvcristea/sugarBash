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
                cmd="${cmd} --db-host ${_db_mysql_connect_host} --db-port ${_db_mysql_port} --db-name turbinado"
            fi
            secho "${cmd}" 'menu'
            ${cmd} &
            ssudo 'tail -f /tmp/nusim/nusim.log'
            local localIpCmd="ip -f inet addr show eth1 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*'"
            local ipVal=$(eval "${localIpCmd}")
            secho "http://${ipVal}/${_nusim_sugar_name}/${_nusim_sugar_flavor}" 'green'
        ;;

        'createInstallPack')
            local dockerImageName="build_core_install_${_nusim_build_number}"
            if [ "${_nusim_build_with_nomad}" == 'true' ]; then
                gitCloneOrUpdate ${_git_GitHub_nomad} ${_nusim_tmppath}/repo nomad ${_nusim_build_branch_nomad}
            fi
            gitCloneOrUpdate ${_git_GitHub_translations} ${_nusim_tmppath}/repo translations ${_nusim_build_branch_translations}
            gitCloneOrUpdate ${_git_GitHub_refinery} ${_nusim_tmppath}/repo refinery ${_nusim_build_branch_refinery}

            mkdir -p ${_nusim_tmppath}/builds/refinery/${_nusim_build_number}

            local cmd="nusim package:create:ps:install -e dev --mango-path ${_nusim_sugar_mango}"
            if [ "${_nusim_build_with_nomad}" == 'true' ]; then
                cmd="${cmd} --nomad-path=${_nusim_tmppath}/repo/nomad"
            fi
            cmd="${cmd} --translations-path ${_nusim_tmppath}/repo/translations"
            cmd="${cmd} --refinery-path ${_nusim_tmppath}/repo/refinery"
            cmd="${cmd} --build-path ${_nusim_tmppath}/builds/${_nusim_build_number}"
            cmd="${cmd} --build-number ${_nusim_build_number}"
            cmd="${cmd} --sugar-version ${_nusim_sugar_version} --sugar-flavor ${_nusim_sugar_flavor}"
            if [ "$ME" == 'vagrant' ]; then
                cmd="echo \"${cmd}\" | sudo su -"
            fi

            secho "${cmd}" 'menu'
            ${cmd} &
            local cmdPID=$!

            cmd="tail -f --pid $cmdPID /tmp/nusim/nusim.log"
            secho "${cmd}" 'menu'
            ${cmd} &

            sleepUnit=3
            sleepCount=0
            while [ -z "$(docker ps -a | grep build_core_install_)" -a $sleepCount -lt 60 ]; do
                sleep $sleepUnit
                let sleepCount=sleepCount+sleepUnit
            done

            cmd="docker logs -f ${dockerImageName}"
            if [ "$ME" == 'vagrant' ]; then
                secho "echo '${cmd} &' | sudo su -" 'menu'
                echo "${cmd}" | sudo su -
            else
                secho "${cmd}" 'menu'
                ${cmd}
            fi

            wait $cmdPID
            secho "nusim command finished" 'menu'

            cp ${_nusim_tmppath}/repo/refinery/build/* ${_nusim_tmppath}/builds/refinery/${_nusim_build_number}
            secho "ls -la ${_nusim_tmppath}/builds/refinery/${_nusim_build_number}" 'menu'
            ls -la ${_nusim_tmppath}/builds/${_nusim_build_number}/refinery

            secho "/** Finished Create Install Pack **/" 'menu'
        ;;

        'createUpgradePack')
            --translations-path=/home/vagrant/git-repo/translations --nomad-path=/home/vagrant/git-repo/nomad --refinery-path=/home/vagrant/git-repo/refinery
            --baseline-path=/var/www/html/SugarEntSvnvcristeaDevelop

            local cmd="nusim package:create:ps:upgrade -e dev --mango-path ${_nusim_sugar_mango}"
            cmd="${cmd} --sugar-version ${_nusim_sugar_version} --sugar-flavor ${_nusim_sugar_flavor}"
            cmd="${cmd} --sugar-version ${_nusim_sugar_version} --sugar-flavor ${_nusim_sugar_flavor}"
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

ci()
{
    secho "# CI: $@" 'menu'

    case ${1} in
        'createInstallPack')
            cd /home/vagrant/AutoUtils/PS/Build_scripts
            ./cs_build.rb --branch=r22 --version=7.7.1.0 --flavor=ult --build_num=r22-0 --upgrade --baseline_path=/tmp/Baseline_path --base_branch=production --build_path=/tmp/Nusim_upgrade_builds/r22-6 --email_recipients=
        ;;

        *)
			break
        ;;
    esac

    drawOptionDone
}
