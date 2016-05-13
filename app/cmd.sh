#!/bin/bash
#===============================================================================
#          FILE:  cmd.sh
#         USAGE:  ./helper.sh -h
#   DESCRIPTION:  SugarCRM bash helper library for Linux
#       AUTHORS:  Nicolae V. CRISTEA;
#       LICENSE:  MIT
#===============================================================================

subCmd()
{
    if [ ! -z "${1}" ] && [ -z "${1##*[!0-9]*}" ]; then
        $1 $2 $3
        exit 1
    fi
}

von()
{
    local stack=${2}
    if [ -z ${stack} ]; then
        setYmlVal "_vagrantON_stack"
        stack=${ymlVal}
    fi

    if [ $1 == "halt" ] || [ $1 == "suspend" ]; then
        mountFstab ${stack} umount &> /dev/null
    elif [ $1 == "up" ] || [ $1 == "resume" ]; then
        vpn connectSugar
    fi

    setYmlVal "_vagrantON_path"
    cd ${ymlVal}/vagrantON
    vagrant $1 ${stack}

    if [ $1 == "up" ] || [ $1 == "resume" ]; then
       mountFstab ${stack}
    fi
}

son()
{
    local stack=${2}
    if [ -z ${stack} ]; then
        setYmlVal "_stacksON_stack"
        stack=${ymlVal}
    fi

    if [ $1 == "halt" ] || [ $1 == "suspend" ]; then
        mountFstab ${stack} umount &> /dev/null
        vpn kill
    elif [ $1 == "up" ] || [ $1 == "resume" ]; then
        vpn connectSugar
    fi

    setYmlVal "_stacksON_path"
    cd ${ymlVal}
    vagrant $1 ${stack}

    if [ $1 == "up" ] || [ $1 == "resume" ]; then
       mountFstab ${stack}
    fi
}

day()
{
    case ${1} in
        'on'|'ON')
            local count=0
            touch ${logFile}
            now=$(date '+%Y-%m-%d %H:%M');
            echo ${now} > ${logFile}
            echo "# Have a nice working day!" >> ${logFile}
            echo "==========================" >> ${logFile}
            setYmlVal "_day_on_${count}"
            while (( ${#ymlVal} > 0 ))
            do
                ${ymlVal} &>> ${logFile} &
                count=$(( $count + 1 ))
                setYmlVal "_day_on_${count}"
            done
        ;;

        'off'|'OFF')
            local count=0
            secho "Bye bye... !" "green"
            echo "Day OFF:  ${now}" >> ${logFile}
            wh >> ${logFile}
            setYmlVal "_day_off_${count}"
            while (( ${#ymlVal} > 0 ))
            do
                ${ymlVal} &>> ${logFile}
                count=$(( $count + 1 ))
                setYmlVal "_day_off_${count}"
            done
            ssudo shutdown -h now
            echo "# Bye bye... !" >> ${logFile}
        ;;

        *)
        ;;
    esac
}

wh(){
    now=$(date '+%Y-%m-%d %H:%M')
    startedAt=$(head -1 $logFile)
    minElapsed=$(( ( $(date -ud "${now}" +'%s') - $(date -ud "${startedAt}" +'%s') )/60 ))
    hElapsed=$((${minElapsed}/60))
    mElapsed=$((${minElapsed}%60))
    if [[ "${#mElapsed}" == 1 ]]; then
        mElapsed="0${mElapsed}"
    fi
    echo At work: ${hElapsed}:${mElapsed}
}

sudoUid()
{
    echo $SUDO_UID
}

oci()
{
    dbOracle $@
}
