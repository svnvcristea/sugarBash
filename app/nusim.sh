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

    newStep 'setVar'

    case ${1} in
        'check')
            nusim list
			which nusim
            nusim -V
        ;;

        'install')
            unixInstall git
            unixInstall composer

            local gitRepoPath="${tmp}/repo"
            rm -rf ${gitRepoPath}/nusim
            mkdir -p ${gitRepoPath}
            cd ${gitRepoPath}
            ssudo "rm /usr/local/bin/nusim"
            secho "# git clone ${_git_GitHub_nusim} ${gitRepoPath}" 'menu'
            git clone -b ${_nusim_install_branch} --recursive ${_git_GitHub_nusim} ./nusim
            cd nusim
            composer install
            ssudo "touch ${tmp}/nusim.log"
            ssudo "chmod 777 ${tmp}/nusim.log"
            secho "* install nusim" 'menu'
            ssudo "php bin/nusim self:compile -e dev -i -v"
            nusim --list
            nusim -V
        ;;

        'installInstance')
            cmdConcat "install:developer -e dev --license-key ${license} --repo-path ${mango}"
            cmdConcat "--instance ${build}${suffix} --sugar-version ${version} --sugar-flavor=${flavor}"
            cmdConcat "--admin-user-name ${adminName} --admin-password ${adminPass}"
            newStep 'dbKeyUser'

            tailPidCmd "${cmd}" "${tmp}/nusim.log"

            wait $cmdPID
            sleep $sleepUnit
            secho "nusim command finished" 'menu'
            
            local localIpCmd="ip -f inet addr show eth1 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*'"
            local ipVal=$(eval "${localIpCmd}")
            secho "http://${ipVal}/${sugarName}/${flavor}" 'green'
        ;;

        'createInstallPack')
            cmdConcat "package:create:${scope}:install -e dev"
            cmdConcat "--mango-path ${mango}"
            cmdConcat "--translations-path ${tmp}/repo/translations"
            cmdConcat "--refinery-path ${tmp}/repo/refinery"
            cmdConcat "--build-path ${tmp}/builds/${build}"
            cmdConcat "--build-number ${build}"
            cmdConcat "--sugar-version ${version}"
            cmdConcat "--config-version ${configv}"
            cmdConcat "--sugar-flavor ${flavor}"

            newStep 'gitCloneOrUpdate' 'refinery'
            if [ "${useN}" == "true" ]; then
                newStep 'gitCloneOrUpdate' 'nomad'
                cmdConcat "--nomad-path=${tmp}/repo/nomad"
            fi
            if [ "${useT}" == "true" ]; then
                newStep 'gitCloneOrUpdate' 'translations'
            else
                cmdConcat "--no-latin"
            fi
            if [ "${useMC}" == "true" ]; then
                newStep 'gitCloneOrUpdate' 'mangoCore'
            fi

            cd ${mango}
            gitMango postCheckout

            nusim -V
            tailPidCmd "${cmd}" "${tmp}/nusim.log"

            local sleepCount=0
            while [ -z "$(docker ps -a | grep build_core_)" -a $sleepCount -lt 300 ]; do
                sleep $sleepUnit
                let sleepCount=sleepCount+sleepUnit
            done

            newStep 'logDocker'

            wait $cmdPID
            sleep $sleepUnit
            secho "nusim command finished" 'menu'

            nusimZipBuild ${build}
            nusimCpFullBuild ${build}

            secho "/** Finished Create Install Pack **/" 'menu'
        ;;

        'createUpgradePack')
            cmdConcat "package:create:ps:upgrade -e dev"
            cmdConcat "--mango-path ${mango}"
            cmdConcat "--translations-path ${tmp}/repo/translations"
            cmdConcat "--refinery-path ${tmp}/repo/refinery"
            cmdConcat "--baseline-path ${tmp}/builds/${build}"
            cmdConcat "--build-path ${tmp}/builds/${upgradePack}"
            cmdConcat "--build-number ${upgradePack}"
            cmdConcat "--sugar-version ${version} "
            cmdConcat "--config-version ${configv}"
            cmdConcat "--sugar-flavor ${flavor}"

            newStep 'gitCloneOrUpdate' 'refinery'
            if [ ${useN} == "true" ]; then
                newStep 'gitCloneOrUpdate' 'nomad'
                cmdConcat "--nomad-path=${tmp}/repo/nomad"
            fi
            if [ ${useT} == "true" ]; then
                newStep 'gitCloneOrUpdate' 'translations'
            else
                cmdConcat "--no-latin"
            fi

            cd ${mango}
            gitMango postCheckout

            nusim -V
            if [ "$ME" == 'vagrant' ]; then
                cmd="echo \"${cmd}\" | sudo su -"
            fi
            tailPidCmd "${cmd}" "${tmp}/nusim.log"

            local sleepCount=0
            while [ -z "$(docker ps -a | grep build_core_)" -a $sleepCount -lt 300 ]; do
                sleep $sleepUnit
                let sleepCount=sleepCount+sleepUnit
            done

            newStep 'logDocker'

            wait $cmdPID
            sleep $sleepUnit
            secho "nusim command finished" 'menu'

            nusimZipBuild ${upgradePack}
            nusimCpFullBuild ${upgradePack}

            secho "/** Finished Create Upgrade Pack **/" 'menu'
        ;;

        'deployInstallPack')
#            local installPack=$(ls ${tmp}/builds/refinery/${build} | grep -oP "^[Sa-z]*.[\.|0-9]*.zip$")
            cmdConcat "package:deploy:${scope}:install -e dev"
            cmdConcat "--package-zip ${tmp}/builds/zip/${build}.zip"
            cmdConcat "--relative-path ${sugarName}"
            cmdConcat "--license-key ${license}"
            newStep 'dbKeyUser'

            nusim -V
            if [ "$ME" == 'vagrant' ]; then
                cmd="echo \"${cmd}\" | sudo su -"
            fi
            tailPidCmd "${cmd}" "${tmp}/nusim.log"
            wait $cmdPID
            sleep $sleepUnit
            secho "nusim command finished" 'menu'
            
            newStep 'gitInit' ${scope}
        ;;

        'deployUpgradePack')
            cmdConcat "package:deploy:${scope}:upgrade -e dev --relative-path ${sugarName}"
            cmdConcat "--package-zip ${tmp}/builds/zip/${upgradePack}.zip"

            if [ "$scope" == 'core' ]; then
                cmdConcat "--silent-upgrader ${tmp}/builds/refinery/${build}/silentUpgrade-PRO-${configv}.zip"
            fi

            if [ "$ME" == 'vagrant' ]; then
                cmd="echo \"${cmd}\" | sudo su -"
            fi

            nusim -V
            tailPidCmd "${cmd}" "${tmp}/nusim.log"
            wait $cmdPID
            sleep $sleepUnit
            secho "nusim command finished" 'menu'
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

newStep() {
    case ${1} in
        'setVar')
            cmd="nusim"
            setYmlVal "_nusim_path_tmp" 'tmp'
            setYmlVal "_nusim_path_mango" 'mango'
            setYmlVal "_nusim_path_root" 'rootPath'
        
            setYmlVal "_nusim_build_db_key" 'dbKey'
            setYmlVal "_db_${dbKey}_type" 'dbType'
            setYmlVal "_db_${dbKey}_port" 'dbPort'
            setYmlVal "_db_${dbKey}_connect_host" 'dbHost'
            setYmlVal "_db_${dbKey}_connect_user" 'dbUser'
            setYmlVal "_db_${dbKey}_connect_pass" 'dbPass'
        
            setYmlVal "_nusim_build_license" 'license'
            setYmlVal "_nusim_build_suffix" 'suffix'
            setYmlVal "_nusim_build_admin_user" 'adminName'
            setYmlVal "_nusim_build_admin_pass" 'adminPass'
        
            setYmlVal "_nusim_build_recipe" 'build'
            setYmlVal "_nusim_recipes_${build}_version" 'version'
            setYmlVal "_nusim_recipes_${build}_configv" 'configv'
            setYmlVal "_nusim_recipes_${build}_flavor" 'flavor'
            setYmlVal "_nusim_recipes_${build}_upgrade" 'upgrade'

            setYmlVal "_nusim_recipes_${build}_use_mangoCore" 'useMC'
            setYmlVal "_nusim_recipes_${build}_use_nomad" 'useN'
            setYmlVal "_nusim_recipes_${build}_use_translations" 'useT'
            setYmlVal "_nusim_recipes_${build}_use_initGit" 'useG'
            setYmlVal "_nusim_recipes_${build}_use_log_docker" 'useD'

            sugarName="${build}${suffix}"
            upgradePack="${build}_${upgrade}"
            if [ "${useMC}" == "true" ]; then
                mango="${tmp}/repo/mangoCore"
            fi

            if [ ${dbKey} == 'oracle' ]; then
                setYmlVal "_db_${dbKey}_createuser_user" 'dbUser'
                setYmlVal "_db_${dbKey}_createuser_pass" 'dbPass'
            fi
        ;;

        'gitCloneOrUpdate')
            setYmlVal "_git_GitHub_${2}" 'gitHubRepo'
            setYmlVal "_nusim_recipes_${build}_${2}_branch" 'branchName'
            setYmlVal "_nusim_recipes_${build}_${2}_commit" 'commit'
            gitCloneOrUpdate ${gitHubRepo} "${tmp}/repo" ${2} ${branchName} ${commit}
        ;;
    
        'dbKey')
            cmdConcat "--db-type ${dbType} --db-host ${dbHost} --db-port ${dbPort}"
            if [ ${dbKey} == 'oracle' ]; then
                sqlPlusCreateUser ${dbUser} ${dbPass}
                cmdConcat "--db-name ${_db_oracle_setRoot_host}/orcl"
            else
                cmdConcat "--db-name ${build,,}_${suffix}"
            fi
        ;;

        'dbKeyUser')
            newStep 'dbKey'
            cmdConcat "--db-user ${dbUser} --db-pass ${dbPass}"
        ;;

        'logDocker')
            local dockerImageName="build_core_${build}"
            setYmlVal "_nusim_recipes_${build}_use_log_docker"
            if [ ${ymlVal} == "true" ]; then
                local cmd="docker logs -f ${dockerImageName}"
                if [ "$ME" == 'vagrant' ]; then
                    secho "echo '${cmd} &' | sudo su -" 'menu'
                    echo "${cmd}" | sudo su -
                else
                    secho "${cmd}" 'menu'
                    ${cmd}
                fi
            fi
        ;;

        'gitInit')
            if [ ${useG} == "true" ]; then
                cd "${_nusim_path_root}/${sugarName}"
                rm -rf .git
                pwd
                gitConfig "initSugarBuild" "- ${2} install pack ${build}"
                chown vagrant:vagrant -R .git
            fi
        ;;

        *)
            break
            ;;
    esac
}

cmdConcat() {
    cmd="${cmd} ${1}"
}

nusimZipBuild() {
    cd ${tmp}/builds/${1}
    zip -rq ${1}.zip ./
    mkdir -p ${tmp}/builds/zip
    mv ${1}.zip ${tmp}/builds/zip
    ls ${tmp}/builds/zip/${1}.zip
}

nusimCpFullBuild() {
    mkdir -p ${tmp}/builds/refinery/${1}
    cp ${tmp}/repo/refinery/build/* ${tmp}/builds/refinery/${1}
    secho "ls -la ${tmp}/builds/refinery/${1}" 'menu'
    ls -la ${tmp}/builds/refinery/${1}
    sudo rm -rf ${tmp}/repo/refinery/build/
}
