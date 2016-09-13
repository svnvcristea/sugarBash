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

unixInstall()
{
    secho "# unixInstall: $@" 'menu'

	case ${1} in
        'composer')
            checkWhich ${cmd}
            if [  "$?" -ne "0"  ]; then
                secho "Install ${1}" 'menu'
                sudo php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
                sudo php -r "if (hash_file('SHA384', 'composer-setup.php') === 'e115a8dc7871f15d853148a7fbac7da27d6c0030b848d9b3dc09e2a0388afed865e6a3d6b3c0fad45c48e2b5fc1196ae') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
                sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer
                sudo php -r "unlink('composer-setup.php');"
            else
                secho "${1} exists" 'green'
            fi
        ;;

        *)
            local cmd="apt-get";
            checkWhich ${cmd}
            if [  "$?" -ne "0"  ]; then
                cmd="yum"; checkWhich ${cmd}
                if [  "$?" -ne "0"  ]; then
                    cmd="zypper"; checkWhich ${cmd}
                    if [  "$?" -ne "0"  ]; then
                        error "Unable to determine Linux install command"
                    fi
                fi
            else
                secho "${1} exists" 'green'
            fi
			secho "Executing: 'sudo ${cmd} install $1'" 'menu'
	        ssudo ${cmd} -y install $1
        ;;

    esac

	drawOptionDone
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

setYmlVal()
{
	ymlVal=${!1}

	if [ ! -z "$2" ]; then
	    eval "${2}=${!1}"
	fi
}

renderArray()
{
    local count=0
	setYmlVal "_$1_${count}_name"

	while (( ${#ymlVal} > 0 ))
	do
	    if [[ ( 10 -gt ${count} ) ]]; then
            echo " ${count} - ${ymlVal}"
	    else
	        echo ${count} - ${ymlVal}
        fi
	    count=$(( $count + 1 ))
	    setYmlVal "_$1_${count}_name"
	done

	draw - '' 'menu'
}

renderOptKeys()
{

    local key="_$1_keys"
	setYmlVal $key

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
        menu)
			code=33
        ;;
        blue)
			code=34
        ;;
        yellow)
			code=93
        ;;
        *)
			code=${2}
        ;;
    esac

    echo -e "\e[${code}m${1}\e[0m"
}

sEncode()
{
    read -s -p "Provide [${1}] password: " OPT
    ymlVal=$( echo ${OPT} | base64 )
    echo -e "\n${1}: ${ymlVal}" >> $DIR/config/_private.yml
}

sDecode()
{
    setYmlVal "_${1}"
    if [ -z ${ymlVal} ]; then
        sEncode ${1}
    fi
    ymlVal=$( echo ${ymlVal} | base64 --decode )
}

ssudo()
{
    setYmlVal "_encode_sudo_use"
    if [ ${ymlVal} == "true" ]; then
        sDecode encode_sudo_pass
        echo ${ymlVal} | sudo -S $@
    else
        sudo -S $@
    fi
}

getBackupPass()
{
    sDecode "backup_pass_encoded"
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
    setYmlVal "_${1/_opt/_name}"
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
        setYmlVal "_${1}_${keys[$OPT]}"
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
        setYmlVal "_${1}_${OPT}_func"
        ${ymlVal}
    done
}

gitCloneOrUpdate()
{
    local repo=${1}
    local path=${2}
    local name=${3}
    local branch='master'

    if [ ! -z "$4" ]; then
        branch=${4}
    fi
    secho "gitCloneOrUpdate ${repo} ${path}/${name} ${branch}" 'menu'

    if [ -d "${path}/${name}" ]; then
        cd ${path}/${name}
        gitStatus=$(git status)
        secho "${gitStatus}"
        if [[ ${gitStatus} == *"On branch"* ]]; then
            git fetch
            git reset --hard origin/${branch}
            git submodule update
            if [ -f composer.json ]; then
                composer install
            fi
        else
            cd ..
            rm -rf ${name}
        fi
    fi

    if [ ! -d "${path}/${name}" ]; then
        mkdir -p ${path}/${name}
        gitClone ${repo} ${path}/${name} ${branch}
    fi
}

gitClone()
{
    secho "# git clone ${1} ${2} -b ${3}" 'menu'
    cd ${2}
    git clone -b ${3} --recursive --depth 1 ${1} ${2}
    if [ -f composer.json ]; then
        composer install
    fi
}