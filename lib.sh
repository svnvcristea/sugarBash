#!/bin/bash 

error() 
{
    echo -e "\033[1;31m${1}\033[0m" 1>&2
    exit 1
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

showOptions()
{
    cat <<EOF

SugarBash Helper 1.0
=====================
EOF

    renderArray "option"
	echo ---------------------

}

menu()
{

    while ((OPT != 0));
    showOptions
    read -p "Select your main menu option: " OPT
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
            sudo vpnc /etc/vpnc/sugarvpn.conf
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
	which ${MOUNT} > /dev/null 2>&1 && which ${RSYNC} > /dev/null 2>&1
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
            setYamlVal "_xbuild_repo_${RID}_name" "repoName";        echo "build name:          ${repoName}"
            setYamlVal "_xbuild_repo_${RID}_path" "repoPath";        echo "source repo path:    ${repoPath}"
            setYamlVal "_xbuild_rootPath" "rootPath";                echo "build destination:   ${rootPath}/${repoName}"
            setYamlVal "_xbuild_repo_${RID}_url" "buildUrl";         echo "build url:           ${buildUrl}"
            setYamlVal "_xbuild_version" "builVersion";              echo "build version        ${builVersion}"
            setYamlVal "_xbuild_flav" "buildFlav";                   echo "build flav:          ${buildFlav}"
            setYamlVal "_xbuild_repo_${RID}_name" "db";              echo "db name:             ${db}"
            setYamlVal "_xbuild_db_user" "dbUser";                   echo "db user:             ${dbUser}"
            setYamlVal "_xbuild_db_password" "dbPass";               echo "db password:         ${dbPass}"
            setYamlVal "_xbuild_license" "license";                  echo "license:             ${license}"
            echo "---------------------"

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
            xbuild installSugar
            xbuild postInstallConfig
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

        'postInstallConfig')

            cat >> config_override.php <<EOL
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
	    query=${query}" '${ymlVal}'"
	    setYamlVal "_xbuild_dbContent_email_addresses_${count}_email_address";      query=${query}",'${ymlVal}'"
        setYamlVal "_xbuild_dbContent_email_addresses_${count}_email_address_caps"; query=${query}",'${ymlVal}'"
        setYamlVal "_xbuild_dbContent_email_addresses_${count}_invalid_email";	    query=${query}",'${ymlVal}'"
        setYamlVal "_xbuild_dbContent_email_addresses_${count}_opt_out";    	    query=${query}",'${ymlVal}'"
        setYamlVal "_xbuild_dbContent_email_addresses_${count}_opt_out";    	    query=${query}",'${ymlVal}'"
        setYamlVal "_xbuild_dbContent_email_addresses_${count}_date_created";    	query=${query}",STR_TO_DATE('${ymlVal}','%Y-%m-%d %H:%i:%s')"
        setYamlVal "_xbuild_dbContent_email_addresses_${count}_date_modified";    	query=${query}",STR_TO_DATE('${ymlVal}','%Y-%m-%d %H:%i:%s')"
        setYamlVal "_xbuild_dbContent_email_addresses_${count}_deleted";    	    query=${query}",'${ymlVal}'"
        query=${query}"); "


	    count=$(( $count + 1 ))
	    setYamlVal "_xbuild_dbContent_email_addresses_${count}_id"
	done


    query==${query}"INSERT INTO email_addr_bean_rel (id,email_address_id,bean_id,bean_module,primary_address,reply_to_address,date_created,date_modified,deleted) VALUES ("
    local count=0
    setYamlVal "_xbuild_dbContent_email_addresses_${count}_id"

    while (( ${#ymlVal} > 0 ))
	do
	    query=${query}" '${ymlVal}'"
	    setYamlVal "_xbuild_dbContent_email_addr_bean_rel_${count}_email_address";      query=${query}",'${ymlVal}'"
        setYamlVal "_xbuild_dbContent_email_addr_bean_rel_${count}_email_address_id";   query=${query}",'${ymlVal}'"
        setYamlVal "_xbuild_dbContent_email_addr_bean_rel_${count}_bean_id";            query=${query}",'${ymlVal}'"
        setYamlVal "_xbuild_dbContent_email_addr_bean_rel_${count}_bean_module";	    query=${query}",'${ymlVal}'"
        setYamlVal "_xbuild_dbContent_email_addr_bean_rel_${count}_primary_address";    query=${query}",'${ymlVal}'"
        setYamlVal "_xbuild_dbContent_email_addr_bean_rel_${count}_reply_to_address";   query=${query}",'${ymlVal}'"
        setYamlVal "_xbuild_dbContent_email_addr_bean_rel_${count}_date_created";    	query=${query}",STR_TO_DATE('${ymlVal}','%Y-%m-%d %H:%i:%s')"
        setYamlVal "_xbuild_dbContent_email_addr_bean_rel_${count}_date_modified";    	query=${query}",STR_TO_DATE('${ymlVal}','%Y-%m-%d %H:%i:%s')"
        setYamlVal "_xbuild_dbContent_email_addr_bean_rel_${count}_deleted";    	    query=${query}",'${ymlVal}'"
        query=${query}"); "


	    count=$(( $count + 1 ))
	    setYamlVal "_xbuild_dbContent_email_addresses_${count}_id"
	done
}