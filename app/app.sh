#!/bin/bash
#===============================================================================
#          FILE:  app.sh
#         USAGE:  ./helper.sh -h
#   DESCRIPTION:  SugarCRM bash helper library for Linux
#       AUTHORS:  Nicolae V. CRISTEA;
#       LICENSE:  MIT
#===============================================================================

vpn()
{
    secho "# VPN: $@" 'menu'

    case ${1} in

        'kill')
            ssudo killall vpnc
            drawOptionDone
        ;;

        'connectSugar')
            setYmlVal "_vpn_conf"
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
            setYmlVal "_git_path" 'gitRepoPath'
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
vendor/
_PSBook/

include/javascript/yui3/
include/javascript/yui/
include/javascript/tiny_mce/

custom/blowfish/
custom/history/
custom/modules/Connectors/metadata/connectors.php
custom/modules/*/Ext/**
custom/application/Ext/**
EOL
			git init && git add . && git commit -m "Initial commit ${2}" &> /dev/null
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
            setYmlVal "_git_clone_mango_origin"
            secho "Will clone ${ymlVal} into ${PWD}" 'menu'
            read -p "Give Mango prefix: " OPT
            if [ -z ${OPT} ]; then
                error 'Proceeding abort!'
            fi

            git clone ${ymlVal} "${OPT}-mango"
            cd ${OPT}-mango
            git status
            git remote -v
            setYmlVal "_git_clone_mango_upstream"
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
            xbuild setParameters $2

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
	setYmlVal "_mount_fstab_${1/-/_}_${count}"
	if [[ $2 == "umount" ]]; then
	    cmd="umount"
	fi

	while (( ${#ymlVal} > 0 ))
	do
	    secho "${cmd} ${ymlVal}" yellow
	    ssudo "${cmd} ${ymlVal}"
	    count=$(( $count + 1 ))
	    setYmlVal "_mount_fstab_${1}_${count}"
	done

    drawOptionDone
}

backup()
{
    setYmlVal "_backup_path" "PATH"
	setYmlVal "_backup_serverip" "SERVER_IP"
	setYmlVal "_backup_mountpoint" "MOUNTPOINT"
	# comenzi 
	setYmlVal "_backup_command_mount" "MOUNT"
	setYmlVal "_backup_command_umount" "UMOUNT"
	setYmlVal "_backup_command_rsync" "RSYNC"
	setYmlVal "_backup_command_domain" "DOMAIN"
	setYmlVal "_backup_command_username" "USERNAME"
	# ----------------------------------------------

	if [ ! "$SUDO_UID" ]; then
	    SUDO_UID=$(ssudo bash $0 sudoUid)
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

    getBackupPass
	ssudo ${MOUNT} '//'${SERVER_IP}'/'${USERNAME} ${MOUNTPOINT} -o username=${USERNAME},domain=${DOMAIN},uid=${SUDO_UID},password=${ymlVal}

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
	ssudo ${UMOUNT} ${MOUNTPOINT} || ${UMOUNT} -l ${MOUNTPOINT} || echo "Umounting failed. Please run  $UMOUNT $MOUNTPOINT"

    drawOptionDone
    exit 1
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
            if [ -z "$2" ]; then
                read -p "Choose repo: " RID
            else
                RID=$2
            fi
            setYmlVal "_xbuild_repo_${RID}_name" "repoName"
            setYmlVal "_xbuild_repo_${RID}_path" "repoPath"
            setYmlVal "_xbuild_repo_${RID}_rootPath" "rootPath"
            setYmlVal "_xbuild_repo_${RID}_url" "buildUrl"
            setYmlVal "_xbuild_repo_${RID}_name" "db"
            setYmlVal "_xbuild_repo_${RID}_db_user" "dbUser"
            setYmlVal "_xbuild_repo_${RID}_db_password" "dbPass"
            setYmlVal "_xbuild_repo_${RID}_db_host" "dbHost"
            setYmlVal "_xbuild_repo_${RID}_db_type" "dbType"
            setYmlVal "_xbuild_repo_${RID}_db_demoData" "dbDemoData"
            setYmlVal "_xbuild_repo_${RID}_db_encryption" "dbEncryption"
            setYmlVal "_xbuild_repo_${RID}_db_encryptionPass" "dbEncryptionPass"
            setYmlVal "_xbuild_repo_${RID}_version" "builVersion"
            setYmlVal "_xbuild_repo_${RID}_flav" "buildFlav"
            setYmlVal "_xbuild_repo_${RID}_license" "license"
            if [ -z ${rootPath} ]; then
                setYmlVal "_xbuild_rootPath" "rootPath"
            fi
            if [ -z ${builVersion} ]; then
                setYmlVal "_xbuild_version" "builVersion"
            fi
            if [ -z ${buildFlav} ]; then
                setYmlVal "_xbuild_flav" "buildFlav"
            fi
            if [ -z ${license} ]; then
                setYmlVal "_xbuild_license" "license"
            fi
            if [ -z ${dbUser} ]; then
                setYmlVal "_xbuild_db_user" "dbUser"
            fi
            if [ -z ${dbPass} ]; then
                setYmlVal "_xbuild_db_password" "dbPass"
            fi
            if [ -z ${dbHost} ]; then
                setYmlVal "_xbuild_db_host" "dbHost"
            fi
            if [ -z ${dbType} ]; then
                setYmlVal "_xbuild_db_type" "dbType"
            fi
            if [ -z ${dbType} ]; then
                setYmlVal "_xbuild_db_demoData" "dbDemoData"
            fi
            if [ -z ${dbEncryption} ]; then
                setYmlVal "_xbuild_db_encryption" "dbEncryption"
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
                dbMySQL setRoot
                mysqlCLI "drop database if exists ${db};"
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
#    'setup_fts_skip' => 'true',
EOL
           fi
           cat >> config_si.php <<EOL
);
EOL
            dbOracle setRoot
            sqlPlusCLI "DROP DATABASE IF EXISTS ${db}; DROP USER ${db} CASCADE;"
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

        'PSBook')
            wget https://github.com/sugarcrm-ps/PSBook/archive/master.tar.gz -O - | tar xz
            mv PSBook-master _PSBook
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
            xbuild PSBook
        ;;

    esac

    drawOptionDone
}

queryDBContent()
{
    query="INSERT INTO email_addresses (id,email_address,email_address_caps,invalid_email,opt_out,date_created,date_modified,deleted) VALUES (";
    local count=0
    setYmlVal "_xbuild_dbContent_email_addresses_${count}_id"

    while (( ${#ymlVal} > 0 ))
	do
	    key="_xbuild_dbContent_email_addresses_"
	    query=${query}" '${ymlVal}'"
	    setYmlVal "${key}${count}_email_address";      query=${query}",'${ymlVal}'"
        setYmlVal "${key}${count}_email_address_caps"; query=${query}",'${ymlVal}'"
        setYmlVal "${key}${count}_invalid_email";	    query=${query}",'${ymlVal}'"
        setYmlVal "${key}${count}_opt_out";    	    query=${query}",'${ymlVal}'"
        setYmlVal "${key}${count}_opt_out";    	    query=${query}",'${ymlVal}'"
        setYmlVal "${key}${count}_date_created";    	query=${query}",STR_TO_DATE('${ymlVal}','%Y-%m-%d %H:%i:%s')"
        setYmlVal "${key}${count}_date_modified";    	query=${query}",STR_TO_DATE('${ymlVal}','%Y-%m-%d %H:%i:%s')"
        setYmlVal "${key}${count}_deleted";    	    query=${query}",'${ymlVal}'"
        query=${query}"); "


	    count=$(( $count + 1 ))
	    setYmlVal "_xbuild_dbContent_email_addresses_${count}_id"
	done

    query==${query}"INSERT INTO email_addr_bean_rel (id,email_address_id,bean_id,bean_module,primary_address,reply_to_address,date_created,date_modified,deleted) VALUES ("
    local count=0
    setYmlVal "_xbuild_dbContent_email_addresses_${count}_id"

    while (( ${#ymlVal} > 0 ))
	do
	    key="_xbuild_dbContent_email_addr_bean_rel_"
	    query=${query}" '${ymlVal}'"
	    setYmlVal "${key}${count}_email_address";      query=${query}",'${ymlVal}'"
        setYmlVal "${key}${count}_email_address_id";   query=${query}",'${ymlVal}'"
        setYmlVal "${key}${count}_bean_id";            query=${query}",'${ymlVal}'"
        setYmlVal "${key}${count}_bean_module";	    query=${query}",'${ymlVal}'"
        setYmlVal "${key}${count}_primary_address";    query=${query}",'${ymlVal}'"
        setYmlVal "${key}${count}_reply_to_address";   query=${query}",'${ymlVal}'"
        setYmlVal "${key}${count}_date_created";    	query=${query}",STR_TO_DATE('${ymlVal}','%Y-%m-%d %H:%i:%s')"
        setYmlVal "${key}${count}_date_modified";    	query=${query}",STR_TO_DATE('${ymlVal}','%Y-%m-%d %H:%i:%s')"
        setYmlVal "${key}${count}_deleted";    	    query=${query}",'${ymlVal}'"
        query=${query}"); "


	    count=$(( $count + 1 ))
	    setYmlVal "_xbuild_dbContent_email_addresses_${count}_id"
	done
}

importSQLDump()
{
    secho "# importSQLDump: $@" 'menu'

    local dbName=$1
    local sqlDumpFile=$2

    setYmlVal "_db_mysql_connect_host" "dbHost";
    setYmlVal "_db_mysql_connect_user" "dbUser";
    setYmlVal "_db_mysql_connect_pass" "dbPass";

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

    mysqlCLI "CREATE DATABASE IF NOT EXISTS ${dbName}"
	checkWhich pw
	if [  "$?" -eq "0"  ]; then
		mysql -h ${dbHost} -u ${dbUser} -p${dbPass} ${dbName} < ${sqlDumpFile}
    else
        pv -i 1 -p -t -e -r -b ${sqlDumpFile} | mysql -h ${dbHost} -u ${dbUser} -p${dbPass} ${dbName}
	fi

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

        'vbox')
            secho "* vbox:" 'menu'
            lsmod | grep -i vbox
            secho "* vboxguest version:" 'menu'
            lsmod | grep -io vboxguest | xargs modinfo | grep -iw version
            secho "* vboxguest info:" 'menu'
            modinfo vboxguest

            # modprobe vboxguest
            # rcvboxadd setup
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
            setYmlVal "_vagrantON_path"
            cd ${ymlVal}
            setYmlVal "_vagrantON_repo"

            if [ -d vagrantON ]; then
                error "${PWD}/vagrantON exists"
            fi
            secho "Will clone ${ymlVal} into ${PWD}" 'menu'

            git clone ${ymlVal} -b develop
            cd vagrantON
            bash app/setup.sh
        ;;

        *)
            setYmlVal "_vagrantON_path"
            cd ${ymlVal}/vagrantON
            setYmlVal "_vagrantON_stack"
            vagrant ${1} ${ymlVal}
        ;;

    esac

    drawOptionDone
}

setMysqlConfigEditor()
{

    checkWhich mysql_config_editor
	if [  "$?" -ne "0"  ]; then
	    mysql_config_editor -V
        secho "You have to install mysql_config_editor" red
        secho "SuSE: sudo zypper install mysql-community-server-client" green
        secho "Mint: sudo apt-get install mysql-client-5.6" green
        error 'mysql_config_editor is required !'
	fi

    setYmlVal "_db_mysql_connect_host" "dbMysqlRootHost"
    setYmlVal "_db_mysql_connect_user" "dbMysqlRootUser"
    setYmlVal "_db_mysql_connect_pass" "dbMysqlRootPass"

    local loginPath="$(echo 'quit' | mysql --login-path=sugarBash 2>&1)"
    if [[ ${loginPath} =~ ^ERROR.* ]]; then
        secho "${loginPath}" red
        mysql_config_editor remove --login-path=sugarBash
    fi

    loginPath="$(mysql_config_editor print --login-path=sugarBash)"
    if [ -z "$loginPath" ]; then
	    secho "Provide the mysql connect password of ${dbMysqlRootUser}@${dbMysqlRootHost}"
        mysql_config_editor set --login-path=sugarBash --host=${dbMysqlRootHost} --user=${dbMysqlRootUser} --password
        mysql_config_editor print --login-path=sugarBash
	fi
}

mysqlCLI()
{
    secho "${1}" menu
    draw - "${#1}" menu
    echo -e "\033[93m";
    cmd="echo \"${1}\" | mysql --login-path=sugarBash"
    eval ${cmd}
    echo -e "\033[0m"
}

dbMySQL()
{
    secho "# DB MySQL: $@" 'menu'

    case ${1} in

        'showUsers')
            mysqlCLI "SELECT User,Host FROM mysql.user;"
        ;;

        'showUserPrivileges')
            read -p "user: " dbMysqlUser
            read -p "host: " dbMysqlHost
            mysqlCLI "SHOW GRANTS FOR '${dbMysqlUser}'@'${dbMysqlHost}';"
        ;;

        'setRoot')
            setYmlVal "_db_mysql_setRoot_host" "dbMysqlSetRootHost"
            setYmlVal "_db_mysql_setRoot_user" "dbMysqlSetRootUser"
            setYmlVal "_db_mysql_setRoot_pass" "dbMysqlSetRootPass"

            rootUserError=$(mysqlCLI "SHOW GRANTS FOR '${dbMysqlSetRootUser}'@'${dbMysqlSetRootHost}';" | grep "Grants for")
            if [ "${#rootUserError}" == 0 ]; then
                setMysqlConfigEditor
                mysqlCLI "CREATE USER '${dbMysqlSetRootUser}'@'${dbMysqlSetRootHost}' IDENTIFIED BY '${dbMysqlSetRootPass}';"
                mysqlCLI "GRANT ALL ON *.* TO '${dbMysqlSetRootUser}'@'${dbMysqlSetRootHost}'; SHOW GRANTS FOR '${dbMysqlSetRootUser}'@'${dbMysqlSetRootHost}'; FLUSH PRIVILEGES;"
            else
                mysqlCLI "SHOW GRANTS FOR '${dbMysqlSetRootUser}'@'${dbMysqlSetRootHost}';"
            fi
        ;;

        'dbSize')
            local query="SELECT table_schema as DB, Round(Sum(data_length + index_length) / 1024 / 1024, 2) as MB"
            query+=" FROM information_schema.tables GROUP BY table_schema HAVING DB NOT IN ('information_schema', 'performance_schema');"
            mysqlCLI "${query}"
        ;;

        *)

        ;;

    esac

    drawOptionDone
}

sqlPlusCLI()
{
    local sqlplus='/usr/lib/oracle/12.1/client64/bin/sqlplus'
    local orcl="${_db_oracle_connect_user}/${_db_oracle_connect_pass}@0.0.0.0/orcl"

    secho "${1}" menu
    draw - "${#1}" menu
#    echo -e "\033[93m";
    if [ "${1}" == 'password' ]; then
        echo 'Type `password`'
        ${sqlplus} ${orcl}
    else
        echo "${1}" | ${sqlplus} ${orcl}
    fi
#    echo -e "\033[0m"
}

sqlPlusDropUser()
{
    sqlPlusCLI "DROP ROLE ${1}; DROP USER ${1} CASCADE;"
    sqlPlusCLI "DROP TABLESPACE ${1} INCLUDING CONTENTS AND DATAFILES CASCADE CONSTRAINTS;"
}

sqlPlusCreateUser()
{
    secho "Create oracle user: ${1} | pass: ${2}" menu
    sqlPlusDropUser ${1}
    sqlPlusCLI "CREATE TABLESPACE ${1};"
    sqlPlusCLI "CREATE USER ${1} IDENTIFIED BY ${2} DEFAULT TABLESPACE ${1} TEMPORARY TABLESPACE temp QUOTA UNLIMITED ON ${1};"
    sqlPlusCLI "GRANT CONNECT, RESOURCE, DBA, CREATE DATABASE LINK, CREATE PUBLIC SYNONYM, CREATE SYNONYM, CREATE TYPE, CREATE MATERIALIZED VIEW, CREATE ROLE, CREATE TABLE, CREATE VIEW, CREATE PROCEDURE, CREATE SEQUENCE, CREATE TRIGGER TO ${1};"
}

dbOracle()
{
    secho "# DB dbOracle: $@" 'menu'
    local query=""

    case ${1} in
        'showUsers')
            sqlPlusCLI "SELECT USERNAME, ACCOUNT_STATUS, EXPIRY_DATE FROM dba_users WHERE default_tablespace not in ('SYSAUX');"
        ;;
        'showTablespace')
            sqlPlusCLI "SELECT TABLESPACE_NAME, STATUS, CONTENTS FROM USER_TABLESPACES;"
        ;;
        'createUser')
            local username="${_db_oracle_createuser_name}"
            sqlPlusCreateUser "${_db_oracle_createuser_name}" "${_db_oracle_createuser_pass}"
        ;;
        'changePass')
            sqlPlusCLI 'password'
        ;;
        'passLifetime')
            sqlPlusCLI 'ALTER PROFILE SYSTEM LIMIT PASSWORD_LIFE_TIME UNLIMITED;'
        ;;
        'setRoot')

            setYmlVal "_db_oracle_setRoot_host" "dbOracleSetRootHost"
            setYmlVal "_db_oracle_setRoot_user" "dbOracleSetRootUser"
            setYmlVal "_db_oracle_setRoot_pass" "dbOracleSetRootPass"

            query+="CREATE USER ${dbOracleSetRootUser} IDENTIFIED BY ${dbOracleSetRootUser} "
            query+="DEFAULT TABLESPACE users TEMPORARY TABLESPACE temp QUOTA UNLIMITED ON users; "
            query+="GRANT CONNECT, RESOURCE, DBA, CREATE DATABASE LINK, CREATE PUBLIC SYNONYM, CREATE SYNONYM, "
            query+="CREATE TYPE, CREATE MATERIALIZED VIEW, CREATE ROLE, CREATE TABLE, CREATE VIEW, CREATE PROCEDURE, "
            query+="CREATE SEQUENCE, CREATE TRIGGER TO ${dbOracleSetRootUser};"
            sqlPlusCLI "${query}"
        ;;

        *)

        ;;

    esac

    drawOptionDone
}

PHPUnit()
{
    secho "# PHPUnit: $@" 'menu'

    case ${1} in

        'install')
            unixInstall phpunit
        ;;

        'install_last')
            wget https://phar.phpunit.de/phpunit.phar -O phpunit.phar
            chmod +x phpunit.phar
            ssudo mv phpunit.phar /usr/local/bin/phpunit
            phpunit --version
        ;;

        'runCustomizationTestSuite')
            xbuild setParameters
            secho "# SugarCRM Instance: ${rootPath}/${repoName} " 'menu'
            cd ${rootPath}/${repoName}/tests
            phpunit --testsuite "Sugar Customization Test Suite"
        ;;

        *)

        ;;

    esac

    drawOptionDone
}
