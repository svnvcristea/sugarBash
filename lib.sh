#!/bin/bash 

error() 
{
    echo -e "\033[1;31m${1}\033[0m" 1>&2
    draw line
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
    echo "You may add the Sugar Bash Helper as alias using:"
    echo ${aliasHelper}
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
	    echo ${count} - ${ymlVal}
	    count=$(( $count + 1 ))
	    setYamlVal "_$1_${count}_name"
	done
}

draw()
{
    case ${1} in
        'line')
			echo "______________________________________________"
        ;;
        'sp_long')
			echo "----------------------------------------------"
        ;;
        'sp')
			echo "-----------------------"
        ;;
        *)
			echo ""
        ;;
    esac
}

showOptions()
{
    cat <<EOF

SugarBash Helper 1.0
=====================
EOF

    renderArray "option"
	draw sp

}

menu()
{
    draw line
    helperAlias
    while ((OPT != 0));
        showOptions
        if [ ! -z $1 ] && [ "${OPT}" == "" ]; then
            OPT=${1}
        else
            read -p "Select your main menu option: " OPT
            draw line
        fi
    do
        setYamlVal "_option_${OPT}_func"
        ${ymlVal}
    done

}

vpn() 
{
    echo "## VPN: $@"

    case ${1} in

        'kill')
            sudo killall vpnc
            break
        ;;

        'connectSugar')
            setYamlVal "_vpn_conf"
            sudo vpnc ${ymlVal}
            break
        ;;

        *)
			break
        ;;

    esac

    echo "-> FINISH"
}

gitConfig() 
{
    echo "## gitConfig: $@"

    case ${1} in

        'global')
			echo "Before config:"
			echo ${_git_user_name}
            git config --global -l
            git config --global user.name "${_git_user_name}"
            git config --global user.email "${_git_user_email}"
            echo "After config:"
            git config --global -l
            break
        ;;

        'cloneMango')
            setYamlVal "_git_clone_mango_origin"
            echo "Will clone ${ymlVal} into ${PWD}"
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
            git fetch upstream
            git submodule update --init
            cd sugarcrm
            composer install
        ;;

        *)
			break
        ;;

    esac

    echo "-> FINISH"
}

mountFstab()
{
    echo "## mountFstab: $@"

	local count=0
	setYamlVal "_mount_fstab_${count}"

	while (( ${#ymlVal} > 0 ))
	do
	    sudo mount ${ymlVal}
	    count=$(( $count + 1 ))
	    setYamlVal "_mount_fstab_${count}"
	done    

    echo "-> FINISH"
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
		error "Use sudo $0 $@"
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

}

askToProceed()
{
    read -p "Proceed $1 ? (y/n): " OPT
    if [ ${OPT} != "y" ]; then
        error 'Proceeding abort!'
    fi
}

xbuild()
{
    echo "## xbuild: $@"

    case ${1} in

        'prepare')

            renderArray "xbuild_repo"
            read -p "Choose repo to build: " RID

            echo "# Build Info #"
            setYamlVal "_xbuild_repo_${RID}_name" "repoName"
            setYamlVal "_xbuild_repo_${RID}_path" "repoPath"
            setYamlVal "_xbuild_rootPath" "rootPath"
            setYamlVal "_xbuild_repo_${RID}_url" "buildUrl"
            setYamlVal "_xbuild_repo_${RID}_name" "db"
            setYamlVal "_xbuild_db_user" "dbUser"
            setYamlVal "_xbuild_db_password" "dbPass"

            setYamlVal "_xbuild_repo_${RID}_version" "builVersion"
            setYamlVal "_xbuild_repo_${RID}_flav" "buildFlav"
            setYamlVal "_xbuild_repo_${RID}_license" "license"
            if [ -z ${builVersion} ]; then
                setYamlVal "_xbuild_version" "builVersion"
            fi
            if [ -z ${buildFlav} ]; then
                setYamlVal "_xbuild_flav" "buildFlav"
            fi
            if [ -z ${license} ]; then
                setYamlVal "_xbuild_license" "license"
            fi

            echo "build name:          ${repoName}"
            echo "source path:         ${repoPath}"
            echo "destination:         ${rootPath}/${repoName}"
            echo "db name:             ${db}"
            echo "db user:             ${dbUser}"
            echo "db password:         ${dbPass}"
            echo "url:                 ${buildUrl}"
            echo "flav:                ${buildFlav}"
            echo "version              ${builVersion}"
            echo "license:             ${license}"
            draw sp_long

            if [ ! -d ${repoPath} ]; then
                error "Source repo path ${repoPath} aka 'Mango' folder desn't exist! Check config.yml"
            fi

            if [ -d "${rootPath}/${repoName}" ]; then
                echo "Cleaning ${rootPath}/${repoName}"
                cd ${rootPath}/${repoName}
                pwd
                askToProceed "to remove folder content"
                rm -Rf ./*
                rm -Rf .htaccess .git
            else
                mkdir ${rootPath}/${repoName}
            fi

            if [ -d "/tmp/sugarbuild$repoName" ]; then
                rm -Rf /tmp/sugarbuild${repoName}
            fi

            askToProceed "building..."

            xbuild building
            xbuild configBuild
            xbuild configOverride
            xbuild installSugar
            xbuild gitRepoInit
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
            echo "drop database if exists ${db};" | mysql -u ${dbUser} -p${dbPass}
            cd ${rootPath}/${repoName}
            cat >config_si.php <<EOL
<?php

\$sugar_config_si = array (
'setup_site_admin_user_name'=>'admin',
'setup_site_admin_password' => 'admin',
'setup_fts_type' => 'Elastic',
'setup_fts_host' => 'localhost',
'setup_fts_port' => '9200',
#'setup_fts_hide_config' => 'true',

'setup_db_host_name' => 'localhost',
'setup_db_database_name' => '$db',
'setup_db_drop_tables' => 1,
'setup_db_create_database' => 1,
'setup_db_admin_user_name' => '$dbUser',
'setup_db_admin_password' => '$dbPass',
'setup_db_type' => 'mysql',

'setup_license_key' => '$license',
'setup_system_name' => 'SugarCRM',
'setup_site_url' => 'http://$url',
);
EOL

cat > .gitignore <<EOL
.idea/
cache/
sugarcrm.log
config_override.php
custom/history/
upload/

include/javascript/yui3/
include/javascript/yui/
include/javascript/tiny_mce/

custom/modules/Connectors/metadata/connectors.php
custom/modules/*/Ext/**
custom/application/Ext/**
EOL
        ;;

        'installSugar')
            local installHtml=$(curl -XGET "http://${buildUrl}/install.php?goto=SilentInstall&cli=true" 2>/dev/null)

            if [[ ${installHtml} == *\<bottle\>Success\!\</bottle\>* ]]
            then
                echo 'Successfull'
            else
                echo "$installHtml" > /tmp/${repoName}_installation_fail.html
                error "Installation failed! Please refer install.log, sugarcrm.log and /tmp/${repoName}_installation_fail.html"
            fi
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

        'dbContent')

            queryDBContent
            echo ${query} | mysql -u ${dbUser} -p${dbPass} ${db}

        ;;

        'gitRepoInit')
            git init && git add . && git commit -m 'Initial commit' > /dev/null
        ;;

        *)
            xbuild prepare
            echo "-> FINISH"
			break
        ;;

    esac
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

    echo "-> Proceed importing ${sqlDumpFile} into ${dbName}@${dbHost}"

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
	sudo ${cmd} install $1
}

sysInfo()
{
    case ${1} in
        'OS')
            OS=$(lsb_release -si)
            ARCH=$(uname -m)
            VER=$(lsb_release -sr)
            SHELL=$(ps -p $$ | tail -1 | awk '{ print $4 }')
            FULL=$(uname -a)

            draw sp_long
            echo " OS:       ${OS}"
            echo " ARCH:     ${ARCH}"
            echo " VER:      ${VER}"
            echo " SHELL:    ${SHELL}"
            echo " FULL:     ${FULL}"
            draw sp_long
        ;;

        'disk')
			df -H
			draw sp_long
        ;;

        'foldersSize')
            echo "# Actual folder size:"
			du -hs ./
			draw sp_long
        ;;

        'top10folders')
            echo "# Top 10 sub-folders:"
			sudo find ./ -type d -print0 | xargs -0 du | sort -n | tail -10 | cut -f2 | xargs -I{} du -sh {}
			draw sp_long
        ;;

        *)
			sysInfo OS
			sysInfo disk
            sysInfo foldersSize
			sysInfo top10folders
        ;;

    esac

}
