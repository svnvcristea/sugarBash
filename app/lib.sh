#!/bin/bash
#===============================================================================
#          FILE:  lib.sh
#         USAGE:  ./helper.sh -h
#   DESCRIPTION:  SugarCRM bash helper library for Linux
#       AUTHORS:  Nicolae V. CRISTEA;
#       LICENSE:  MIT
#===============================================================================

error() 
{
    echo -e "\033[1;31m${1}\033[0m" 1>&2
    draw _ ${#1} red
    exit 1
}

checkWhich()
{
    which ${1} > /dev/null 2>&1
    return $?
}

helperAlias()
{
    local aliasHelper="alias helper='bash ${DIR}/helper.sh'"
    if [ "$PWD" == "${DIR}" ]; then
        secho "You may add the Sugar Bash Helper as alias using:" menu
        secho "${aliasHelper}" green
        secho "or add permanent alias trough" menu
        secho "echo \"${aliasHelper}\" >> ~/.bashrc" green
    fi
}

parse_yaml()
{
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F${fs} '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'${prefix}'",vn, $2, $3);
      }
   }'
}

setYamlVal()
{
	ymlVal=${!1}

	if [ ! -z "$2" ]; then
	    eval ${2}=${!1}
	fi
}

renderArray()
{
    local count=0
	setYamlVal "_$1_${count}_name"

	while (( ${#ymlVal} > 0 ))
	do
	    if [[ ( 10 -gt ${count} ) ]]; then
            echo " ${count} - ${ymlVal}"
	    else
	        echo ${count} - ${ymlVal}
        fi
	    count=$(( $count + 1 ))
	    setYamlVal "_$1_${count}_name"
	done

	draw - '' 'menu'
}

renderOptKeys()
{

    local key="_$1_keys"
	setYamlVal $key

	eval keys="(${ymlVal})"

	for key in ${!keys[@]}; do
	    if [[ ( 10 -gt ${key} ) ]]; then
            echo " ${key} - ${keys[$key]}"
	    else
	        echo ${key} - ${keys[$key]}
        fi
    done

	draw - '' 'menu'
}

#   FUNCTION:   secho       Echo the message into specific color
# PARAMETERS:   $1          The message to display
#               $2          The color of the message
secho()
{
    local code=0

    case ${2} in
        red)
			code=31
        ;;
        green)
			code=32
        ;;
        yellow|menu)
			code=33
        ;;
        blue)
			code=34
        ;;
        *)
			code=${2}
        ;;
    esac

    echo -e "\e[${code}m${1}\e[0m"
}

sEncode()
{
    read -s -p "Provide [sudo] password for $USER: " OPT
    ymlVal=$( echo ${OPT} | base64 )
    echo -e "\nencode_sudo_pass: ${ymlVal}" >> $DIR/config/_private.yml
}

sDecode()
{
    setYamlVal "_encode_sudo_pass"
    if [ -z ${ymlVal} ]; then
        sEncode
    fi
    ymlVal=$( echo ${ymlVal} | base64 --decode )
}

ssudo()
{
    setYamlVal "_encode_sudo_use"
    if [ ${ymlVal} == "true" ]; then
        sDecode
        echo ${ymlVal} | sudo -S $@
    else
        sudo -S $@
    fi
}

#   FUNCTION:   draw        Echo Specific line
# PARAMETERS:   $1          Type of the line
#               $2          Lenght of the line
#               $3          Color of the line
draw()
{
    local line
    local lineLenght=${titleLenght}

    if [ ! -z ${2} ]; then
        lineLenght=${2}
    fi

    for i in `seq 1 ${lineLenght}`;
    do
        line="${line}${1}"
    done
    secho "${line}" ${3}
}

drawOptionDone()
{
    draw - "" 'menu'
}

showTitle()
{

    local title="SugarBash Helper: ${1}"
    echo ""
    secho "${title}" 'menu'
    titleLenght=${#title}
    draw "=" ${titleLenght} 'menu'

}

showOptions()
{
    setYamlVal "_${1/_opt/_name}"
    if [[ -z ${ymlVal} ]]; then
        ymlVal=${1}
    fi

    showTitle ${ymlVal}

    if [[ $2 == "keys" ]]; then
        renderOptKeys $1
    else
        renderArray $1
    fi
}

menuKeys()
{
    ymlVal=''

    while true;
        showOptions $1 'keys'
        read -p "Select your menu option: " OPT
        draw _ "" 'menu'
    do
        setYamlVal "_${1}_${keys[$OPT]}"
        optKey=${keys[$OPT]}
        if [[ ! -z ${ymlVal} ]]; then
           break
        fi

        secho "_${1}_${keys[$OPT]}  ${optKey}: ${ymlVal}"
    done
}

menu()
{
    while (( OPT != 0 ));
        showOptions $1
        if [ ! -z $2 ] && [ "${OPT}" == "" ]; then
            OPT=${2}
        else
            read -p "Select your menu option: " OPT
            draw _ "" 'menu'
        fi
    do
        setYamlVal "_${1}_${OPT}_func"
        ${ymlVal}
    done
}

vpn() 
{
    secho "# VPN: $@" 'menu'

    case ${1} in

        'kill')
            ssudo killall vpnc
            drawOptionDone
        ;;

        'connectSugar')
            setYamlVal "_vpn_conf"
            touch $DIR/log/vpn.log
            ssudo vpnc ${ymlVal} >> $DIR/log/vpn.log
            vpn status
        ;;

        'status')
            OUTPUT=$(ssudo pgrep vpnc)
            echo "PID: $OUTPUT"
            drawOptionDone
        ;;

        *)
			break
        ;;

    esac
}

gitConfig() 
{
    secho "# gitConfig: $@" 'menu'

    case ${1} in

        'global')
			secho "Before config:" 'menu'
            git config --global -l
            git config --global user.name "${_git_user_name}"
            git config --global user.email "${_git_user_email}"
            secho "After config:" 'menu'
            git config --global -l
            drawOptionDone
        ;;

        'clone')

            menuKeys "git_GitHub"
            local repo=${ymlVal}
            setYamlVal "_git_path" 'gitRepoPath'
            secho "#${optKey}: git clone ${repo} ${gitRepoPath}/${optKey}" 'menu'

            git clone ${repo} ${gitRepoPath}/${optKey}
            cd ${gitRepoPath}/${optKey}
            git submodule init
            git submodule update
            git submodule
            git remote -v
            git status

            drawOptionDone
        ;;

        'initSugarBuild')
            cat > .gitignore <<EOL
# OS and IDE
*~
.DS_Store
.idea/
.project
.settings

# SugarCRM
*.log
config_override.php

cache/
upload/

include/javascript/yui3/
include/javascript/yui/
include/javascript/tiny_mce/

custom/blowfish/
custom/history/
custom/modules/Connectors/metadata/connectors.php
custom/modules/*/Ext/**
custom/application/Ext/**
EOL
			git init && git add . && git commit -m 'Initial commit'
        ;;

        *)
			break
        ;;

    esac
}

gitMango()
{
    secho "# gitMango: $@" 'menu'

    case ${1} in

        'clone')
            setYamlVal "_git_clone_mango_origin"
            secho "Will clone ${ymlVal} into ${PWD}" 'menu'
            read -p "Give Mango prefix: " OPT
            if [ -z ${OPT} ]; then
                error 'Proceeding abort!'
            fi

            git clone ${ymlVal} "${OPT}-mango"
            cd ${OPT}-mango
            git status
            git remote -v
            setYamlVal "_git_clone_mango_upstream"
            git remote add upstream ${ymlVal}
            git remote -v
            gitMango postCheckout

        ;;

        'postCheckout')
            git fetch upstream
            git submodule update --init
            git submodule update
            secho "Submodules:" 'menu'
            git submodule
            composer install -d=sugarcrm
		;;

        'patch')
            xbuild setParameters

            secho "# Patch Info #" 'menu'
            echo "Based on staged files of:       ${rootPath}/${repoName}"
            echo "Mango repo applying on:         ${repoPath}/sugarcrm"

            askToProceed "applying patch"

            secho "Creating patch based on staged files from: ${rootPath}/${repoName}" 'menu'
            cd ${rootPath}/${repoName}
            git diff --staged > /tmp/${repoName}.patch
            secho "Apply patch into Mango repo: ${repoPath}/sugarcrm" 'menu'
            cd ${repoPath}/sugarcrm
            patch -p1 < /tmp/${repoName}.patch
            git status
		;;

        *)
			break
        ;;

    esac

    drawOptionDone
}

mountFstab()
{
    secho "# mountFstab: $@" 'menu'

    local cmd="mount"
	local count=0
	setYamlVal "_mount_fstab_${1}_${count}"
	if [[ $2 == "umount" ]]; then
	    cmd="umount"
	fi

	while (( ${#ymlVal} > 0 ))
	do
	    secho "${cmd} ${ymlVal}"
	    ssudo ${cmd} ${ymlVal}
	    count=$(( $count + 1 ))
	    setYamlVal "_mount_fstab_${1}_${count}"
	done

    drawOptionDone
}

backup()
{
    setYamlVal "_backup_path" "PATH"
	setYamlVal "_backup_serverip" "SERVER_IP"
	setYamlVal "_backup_mountpoint" "MOUNTPOINT"
	# comenzi 
	setYamlVal "_backup_command_mount" "MOUNT"
	setYamlVal "_backup_command_umount" "UMOUNT"
	setYamlVal "_backup_command_rsync" "RSYNC"
	setYamlVal "_backup_command_domain" "DOMAIN"
	setYamlVal "_backup_command_username" "USERNAME"
	# ----------------------------------------------

	if [ ! "$SUDO_UID" ]; then
		error "Use sudo bash $0 $@"
	fi

	# ----    aici trebuia sa verific daca exista comenzile
	checkWhich ${MOUNT} && checkWhich ${RSYNC}
	if [  "$?" -ne "0"  ]; then
		unixInstall $MOUNT
		unixInstall $RSYNC
	fi

	checkWhich ${MOUNT} && checkWhich ${RSYNC}
	if [  "$?" -ne "0"  ]; then
		error "Can't find $MOUNT or $RSYNC";
	fi

	if [ ! -d ${MOUNTPOINT} ]; then
		mkdir -p ${MOUNTPOINT} || ( echo "Unable to create mount point. Exiting..." exit 1; )
	fi

	${MOUNT} '//'${SERVER_IP}'/'${USERNAME} ${MOUNTPOINT} -o username=${USERNAME},domain=${DOMAIN},uid=${SUDO_UID}
	if [  "$?" -eq "0"  ]; then
	    echo "Remote folder mounted in $MOUNTPOINT";
	else 
	    error "Error mounting. Exiting" ;
	fi       
	                  
	${RSYNC}
	if [  "$?" -eq "0"  ]; then
		echo "Sync OK";
	else 
		error "Error sync folders" ;
	fi       
	${UMOUNT} ${MOUNTPOINT} || ${UMOUNT} -l ${MOUNTPOINT} || echo "Umounting failed. Please run  $UMOUNT $MOUNTPOINT"

    drawOptionDone
}

askToProceed()
{
    echo -e "\033[93m"; read -e -p "Proceed $1 ? (y/n): " -i "y" OPT ; echo -e "\033[0m"
    if [ ${OPT} != "y" ] && [ -z ${2} ]; then
        error 'Proceeding abort!'
    fi
}

diskBenchmark()
{
    local count=512
    local testFiles="./t3st7i1e_1.tmp ./t3st7i1e_2.tmp ./t3st7i1e_3.tmp"

	if [ ! -z "$1" ]; then
	    count=${1}
	fi

    secho "New: bs=1M count=${count}" 'menu'
    for testFile in ${testFiles};
    do
        if [ -f ${testFile} ]; then
            ls -l ${testFile}
            echo -e "\033[93m"; read -e -p "Remove ${testFile} ? (y/n): " -i "y" OPT ; echo -e "\033[0m"
            if [ ${OPT} != "y" ]; then
                rm ${testFile}
            fi
        fi
        dd if=/dev/zero of=${testFile} bs=1M count=${count}
    done

    secho "Same: bs=1M count=${count}" 'menu'
    for testFile in ${testFiles};
    do
        dd if=/dev/zero of=${testFile} bs=1M count=${count}
        rm ${testFile}
    done
}

xbuild()
{
    secho "# xbuild: $@" 'menu'

    case ${1} in

        'setParameters')
            renderArray "xbuild_repo"
            read -p "Choose repo: " RID

            setYamlVal "_xbuild_repo_${RID}_name" "repoName"
            setYamlVal "_xbuild_repo_${RID}_path" "repoPath"
            setYamlVal "_xbuild_repo_${RID}_rootPath" "rootPath"
            setYamlVal "_xbuild_repo_${RID}_url" "buildUrl"
            setYamlVal "_xbuild_repo_${RID}_name" "db"
            setYamlVal "_xbuild_repo_${RID}_db_user" "dbUser"
            setYamlVal "_xbuild_repo_${RID}_db_password" "dbPass"
            setYamlVal "_xbuild_repo_${RID}_db_host" "dbHost"
            setYamlVal "_xbuild_repo_${RID}_db_type" "dbType"
            setYamlVal "_xbuild_repo_${RID}_db_demoData" "dbDemoData"
            setYamlVal "_xbuild_repo_${RID}_db_encryption" "dbEncryption"
            setYamlVal "_xbuild_repo_${RID}_db_encryptionPass" "dbEncryptionPass"
            setYamlVal "_xbuild_repo_${RID}_version" "builVersion"
            setYamlVal "_xbuild_repo_${RID}_flav" "buildFlav"
            setYamlVal "_xbuild_repo_${RID}_license" "license"
            if [ -z ${rootPath} ]; then
                setYamlVal "_xbuild_rootPath" "rootPath"
            fi
            if [ -z ${builVersion} ]; then
                setYamlVal "_xbuild_version" "builVersion"
            fi
            if [ -z ${buildFlav} ]; then
                setYamlVal "_xbuild_flav" "buildFlav"
            fi
            if [ -z ${license} ]; then
                setYamlVal "_xbuild_license" "license"
            fi
            if [ -z ${dbUser} ]; then
                setYamlVal "_xbuild_db_user" "dbUser"
            fi
            if [ -z ${dbPass} ]; then
                setYamlVal "_xbuild_db_password" "dbPass"
            fi
            if [ -z ${dbHost} ]; then
                setYamlVal "_xbuild_db_host" "dbHost"
            fi
            if [ -z ${dbType} ]; then
                setYamlVal "_xbuild_db_type" "dbType"
            fi
            if [ -z ${dbType} ]; then
                setYamlVal "_xbuild_db_demoData" "dbDemoData"
            fi
            if [ -z ${dbEncryption} ]; then
                setYamlVal "_xbuild_db_encryption" "dbEncryption"
            fi
            db=${db//[^[:alnum:]]/}
        ;;

        'prepare')
            secho "# Build Info #" 'menu'
            echo "build name:          ${repoName}"
            echo "source path:         ${repoPath}"
            echo "destination:         ${rootPath}/${repoName}"
            echo "db name:             ${db}"
            echo "db user:             ${dbUser}"
            echo "db password:         ${dbPass}"
            echo "db host:             ${dbHost}"
            echo "db type:             ${dbType}"
            echo "db demoData:         ${dbDemoData}"
            echo "db encryption:       ${dbEncryption}"
            echo "db encryption pass:  ${dbEncryptionPass}"
            echo "url:                 ${buildUrl}"
            echo "flav:                ${buildFlav}"
            echo "version              ${builVersion}"
            echo "license:             ${license}"
            draw - 60

            if [ ! -d ${repoPath} ]; then
                error "Source repo path ${repoPath} aka 'Mango' folder desn't exist! Check config.yml"
            fi

            if [ -d "${rootPath}/${repoName}" ]; then
                secho "Cleaning ${rootPath}/${repoName}"
                cd ${rootPath}/${repoName}
                askToProceed "to remove folder content"
                proceedXBuild=1
                rm -Rf ./*
                rm -Rf .htaccess .git .gitignore
            else
                mkdir ${rootPath}/${repoName}
            fi

            if [ -d "/tmp/sugarbuild$repoName" ]; then
                rm -Rf /tmp/sugarbuild${repoName}
            fi

            cd ${repoPath}
            gitMango postCheckout
        ;;

        'building')
            cd ${repoPath}/build/rome

            php -n build.php \
            --ver=${builVersion} \
            --flav=${buildFlav} \
            --dir=sugarcrm \
            --build_dir=/tmp/sugarbuild_${repoName}

            mv /tmp/sugarbuild_${repoName}/${buildFlav}/sugarcrm/* ${rootPath}/${repoName}
        ;;

        'configBuild')
            if [[  "${dbType}" == "mysql"  ]]; then
                echo "drop database if exists ${db};" | mysql -u ${dbUser} -p${dbPass}
            fi
            cd ${rootPath}/${repoName}
            cat > config_si.php <<EOL
<?php

\$sugar_config_si = array (
    'setup_site_admin_user_name'=>'admin',
    'setup_site_admin_password' => 'admin',

    'setup_db_host_name' => '${dbHost}',
    'setup_db_database_name' => '${db}',
    'setup_db_drop_tables' => 'true',
    'setup_db_create_database' => 'true',
    'setup_db_admin_user_name' => '${dbUser}',
    'setup_db_admin_password' => '${dbPass}',
    'setup_db_type' => '${dbType}',

    'demoData' => '${dbDemoData}',

    'setup_license_key' => '${license}',
    'setup_system_name' => 'SugarCRM',
    'setup_site_url' => 'http://${buildUrl}',

    'default_currency_iso4217' => 'USD',
    'default_currency_name' => 'US Dollar',
    'default_currency_significant_digits' => '2',
    'default_currency_symbol' => '$',
    'default_date_format' => 'Y-m-d',
    'default_time_format' => 'H:i',
    'default_decimal_seperator' => '.',
    'default_language' => 'en_us',
    'default_locale_name_format' => 's f l',
    'default_number_grouping_seperator' => ',',
    'export_delimiter' => ',',

    'setup_fts_type' => 'Elastic',
    'setup_fts_host' => 'localhost',
    'setup_fts_port' => '9200',
    #'setup_fts_hide_config' => 'true',

EOL
            if [[  "${dbType}" == "oci8"  ]]; then
                secho "Oracle Db config" 'menu'

                cat >> config_si.php <<EOL
# Config Oracle DB
    'setup_db_create_sugarsales_user' => 'false',
    'setup_license_key_users' => '100',
    'setup_license_key_expire_date' => '2016-10-01',
    'setup_num_lic_oc' => '10',
    'dbUSRData' => 'same',
    'install_type' => 'typical',
    'setup_db_pop_demo_data' => '0',
    'setup_site_sugarbeet_anonymous_stats' => 'true',
    'setup_site_sugarbeet_automatic_checks' => '1',
    'setup_db_database_name' => '0.0.0.0/orcl',
#    'web_user' => 'vagrant',
#    'web_group' => 'apache',
    'setup_fts_skip' => 'true',
EOL
           fi
           cat >> config_si.php <<EOL
);
EOL

        ;;

        'configOverride')

            cat >> config_override.php <<EOL
<?php

\$sugar_config['developerMode'] = true;
\$sugar_config['passwordsetting']['minpwdlength'] = '';
\$sugar_config['passwordsetting']['oneupper'] = '0';
\$sugar_config['passwordsetting']['onelower'] = '0';
\$sugar_config['passwordsetting']['onenumber'] = '0';
\$sugar_config['passwordsetting']['onespecial'] = '0';
\$sugar_config['passwordsetting']['SystemGeneratedPasswordON'] = '0';
EOL
        ;;

        'installSugar')
            local installHtml=$(curl -XGET "http://${buildUrl}/install.php?goto=SilentInstall&cli=true" 2>/dev/null)

            if [[ ${installHtml} == *\<bottle\>Success\!\</bottle\>* ]]; then
                echo 'Successfull'
                if [ ${dbEncryption} == "true" ]; then
                    cat >> config_override.php <<EOL
\$sugar_config['dbconfig']['use_encryption'] = ${dbEncryption};
\$sugar_config['dbconfig']['db_password'] = '${dbEncryptionPass}';
EOL
                fi
            else
                echo "-> cat install.log"
                cat ${rootPath}/${repoName}/install.log
                draw -
                echo "-> cat sugarcrm.log"
                cat ${rootPath}/${repoName}/sugarcrm.log
                draw -
                echo "-> cat /tmp/${repoName}_installation_fail.html"
                echo "$installHtml" > /tmp/${repoName}_installation_fail.html
                draw -
                error "Installation failed! Please refer install.log, sugarcrm.log and /tmp/${repoName}_installation_fail.html"
            fi
        ;;

        'dbContent')

            queryDBContent
            echo ${query} | mysql -u ${dbUser} -p${dbPass} ${db}

        ;;

        'gitRepoInit')
            gitConfig initSugarBuild
        ;;

        *)
            xbuild setParameters
            xbuild prepare
            if [ -z ${proceedXBuild} ]; then
                askToProceed "building..."
            fi
            xbuild building
            xbuild configBuild
            xbuild configOverride
            xbuild installSugar
            xbuild gitRepoInit
        ;;

    esac

    drawOptionDone
}

queryDBContent()
{
    query="INSERT INTO email_addresses (id,email_address,email_address_caps,invalid_email,opt_out,date_created,date_modified,deleted) VALUES (";
    local count=0
    setYamlVal "_xbuild_dbContent_email_addresses_${count}_id"

    while (( ${#ymlVal} > 0 ))
	do
	    key="_xbuild_dbContent_email_addresses_"
	    query=${query}" '${ymlVal}'"
	    setYamlVal "${key}${count}_email_address";      query=${query}",'${ymlVal}'"
        setYamlVal "${key}${count}_email_address_caps"; query=${query}",'${ymlVal}'"
        setYamlVal "${key}${count}_invalid_email";	    query=${query}",'${ymlVal}'"
        setYamlVal "${key}${count}_opt_out";    	    query=${query}",'${ymlVal}'"
        setYamlVal "${key}${count}_opt_out";    	    query=${query}",'${ymlVal}'"
        setYamlVal "${key}${count}_date_created";    	query=${query}",STR_TO_DATE('${ymlVal}','%Y-%m-%d %H:%i:%s')"
        setYamlVal "${key}${count}_date_modified";    	query=${query}",STR_TO_DATE('${ymlVal}','%Y-%m-%d %H:%i:%s')"
        setYamlVal "${key}${count}_deleted";    	    query=${query}",'${ymlVal}'"
        query=${query}"); "


	    count=$(( $count + 1 ))
	    setYamlVal "_xbuild_dbContent_email_addresses_${count}_id"
	done

    query==${query}"INSERT INTO email_addr_bean_rel (id,email_address_id,bean_id,bean_module,primary_address,reply_to_address,date_created,date_modified,deleted) VALUES ("
    local count=0
    setYamlVal "_xbuild_dbContent_email_addresses_${count}_id"

    while (( ${#ymlVal} > 0 ))
	do
	    key="_xbuild_dbContent_email_addr_bean_rel_"
	    query=${query}" '${ymlVal}'"
	    setYamlVal "${key}${count}_email_address";      query=${query}",'${ymlVal}'"
        setYamlVal "${key}${count}_email_address_id";   query=${query}",'${ymlVal}'"
        setYamlVal "${key}${count}_bean_id";            query=${query}",'${ymlVal}'"
        setYamlVal "${key}${count}_bean_module";	    query=${query}",'${ymlVal}'"
        setYamlVal "${key}${count}_primary_address";    query=${query}",'${ymlVal}'"
        setYamlVal "${key}${count}_reply_to_address";   query=${query}",'${ymlVal}'"
        setYamlVal "${key}${count}_date_created";    	query=${query}",STR_TO_DATE('${ymlVal}','%Y-%m-%d %H:%i:%s')"
        setYamlVal "${key}${count}_date_modified";    	query=${query}",STR_TO_DATE('${ymlVal}','%Y-%m-%d %H:%i:%s')"
        setYamlVal "${key}${count}_deleted";    	    query=${query}",'${ymlVal}'"
        query=${query}"); "


	    count=$(( $count + 1 ))
	    setYamlVal "_xbuild_dbContent_email_addresses_${count}_id"
	done
}

importSQLDump()
{
    secho "# importSQLDump: $@" 'menu'

    local dbName=$1
    local sqlDumpFile=$2

    setYamlVal "_mysql_host" "dbHost";
    setYamlVal "_mysql_user" "dbUser";
    setYamlVal "_mysql_pass" "dbPass";

    if [ -z ${dbName} ]; then
        read -p "Give DB name: " dbName
    fi

    if [ -z ${sqlDumpFile} ]; then
        echo "-> Actual path: $PWD/"
        ls | grep .sql
        read -p "Give sql dump file to import into ${dbName}: " sqlDumpFile
    fi

    if [ ! -f ${sqlDumpFile} ]; then
        error "${sqlDumpFile} not found"
    fi

    secho "Proceed importing ${sqlDumpFile} into ${dbName}@${dbHost}" 'menu'

    checkWhich pv
	if [  "$?" -ne "0"  ]; then
        unixInstall pv
	fi

	checkWhich pw
	if [  "$?" -eq "0"  ]; then
		mysql -h ${dbHost} -u ${dbUser} -p${dbPass} ${dbName} < ${sqlDumpFile}
    else
        pv -i 1 -p -t -e -r -b ${sqlDumpFile} | mysql -h ${dbHost} -u ${dbUser} -p${dbPass} ${dbName}
	fi

    drawOptionDone
}

unixInstall()
{
    local cmd="apt-get";
    checkWhich ${cmd}
	if [  "$?" -ne "0"  ]; then
		cmd="yum"; checkWhich ${cmd}
        if [  "$?" -ne "0"  ]; then
            cmd="zypper"; checkWhich ${cmd}
            if [  "$?" -ne "0"  ]; then
                error "Unable to determ Linux install command"
            fi
        fi
	fi
    echo "Executing: 'sudo ${cmd} install $1'"
	ssudo ${cmd} install $1
	drawOptionDone
}

sysInfo()
{
    secho "# sysInfo: $@" 'menu'

    case ${1} in
        'OS')
            OS=$(lsb_release -si)
            ARCH=$(uname -m)
            VER=$(lsb_release -sr)
            SHELL=$(ps -p $$ | tail -1 | awk '{ print $4 }')
            FULL=$(uname -a)

            echo " OS:       ${OS}"
            echo " ARCH:     ${ARCH}"
            echo " VER:      ${VER}"
            echo " SHELL:    ${SHELL}"
            echo " FULL:     ${FULL}"
        ;;

        'disk')
			df -H
        ;;

        'foldersSize')
			du -hs ./
        ;;

        'writeTest')
            diskBenchmark 1024
        ;;

        'top10folders')
			ssudo find ./ -type d -print0 | xargs -0 du | sort -n | tail -10 | cut -f2 | xargs -I{} du -sh {}
        ;;

        *)
			sysInfo OS
			sysInfo disk
            sysInfo foldersSize
			sysInfo top10folders
        ;;

    esac

    drawOptionDone
}

vagrantON()
{
    secho "# vagrantON: $@" 'menu'

    case ${1} in

        'clone')
            setYamlVal "_vagrantON_path"
            cd ${ymlVal}
            setYamlVal "_vagrantON_repo"

            if [ -d vagrantON ]; then
                error "${PWD}/vagrantON exists"
            fi
            secho "Will clone ${ymlVal} into ${PWD}" 'menu'

            git clone ${ymlVal}
            cd vagrantON
            git submodule init
            git submodule update
            cp _examples/config.yml ./
            askToProceed "edit config.yml" true
            if [[ ${OPT} == "y" ]]; then
                nano config.yml
            fi

        ;;

        *)
            setYamlVal "_vagrantON_path"
            cd ${ymlVal}/vagrantON
            setYamlVal "_vagrantON_stack"
            vagrant ${1} ${ymlVal}
        ;;

    esac

    drawOptionDone
}

mysqlCLI()
{
    secho "${1}" menu
    draw - "${#1}" menu
    setYamlVal "_db_mysql_localRootPass"
    cmd="echo \"${1}\" | mysql -h localhost -u root -p${ymlVal}"
    eval ${cmd}
}

db()
{
    secho "# db: $@" 'menu'

    case ${1} in

        'mysqlSetRoot')
            setYamlVal "_db_mysql_setRoot_host" "dbMysqlRootHost"
            setYamlVal "_db_mysql_setRoot_user" "dbMysqlRootUser"
            setYamlVal "_db_mysql_setRoot_pass" "dbMysqlRootPass"

            mysqlCLI "SELECT User,Host FROM mysql.user; CREATE USER '${dbMysqlRootUser}'@'${dbMysqlRootHost}' IDENTIFIED BY '${dbMysqlRootPass}';"
            mysqlCLI "GRANT ALL ON *.* TO '${dbMysqlRootUser}'@'${dbMysqlRootHost}'; SHOW GRANTS FOR '${dbMysqlRootUser}'@'${dbMysqlRootHost}'; FLUSH PRIVILEGES;"
        ;;

        *)

        ;;

    esac

    drawOptionDone
}
