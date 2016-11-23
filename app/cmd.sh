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
#        vpn kill
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
            local sleepUnit=5
            touch ${logFile}
            now=$(date '+%Y-%m-%d %H:%M');
            echo ${now} > ${logFile}
            echo "# Have a nice working day!" >> ${logFile}
            echo "==========================" >> ${logFile}
            setYmlVal "_day_on_${count}"
            while (( ${#ymlVal} > 0 ))
            do
                echo "# dayON: ${ymlVal}" >> ${logFile}
                local logFileApp=$logPath/$(date '+%Y-%m-%d')_day_on_
                case "${ymlVal}" in
                    *"phpstorm.sh") logFileApp="${logFileApp}phpstorm.log";;
                    *"thunderbird"*) logFileApp="${logFileApp}thunderbird.log";;
                    *"hipchat"*) logFileApp="${logFileApp}hipchat.log";;
                    *"skype"*) logFileApp="${logFileApp}skype.log";;
                    *"docker"*) logFileApp="${logFileApp}docker.log";;
                    *"son"*) logFileApp="${logFileApp}vagrantON.log";;
                    *) logFileApp="${logFileApp}app.log" ;;
                esac
                touch ${logFileApp}
                if [  "$count" -gt "7"  ]; then
                    sleep $sleepUnit
                fi
                ${ymlVal} &>> ${logFileApp} &
                eval "PID${count}=$!"
                echo "PID${count}: $!" >> ${logFileApp}
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
            local logFileApp=$logPath/$(date '+%Y-%m-%d')_day_off_app.log
            touch ${logFileApp}
            while (( ${#ymlVal} > 0 ))
            do
                echo "# dayOFF: ${ymlVal}" >> ${logFile}
                ${ymlVal} &>> ${logFileApp}
                count=$(( $count + 1 ))
                setYmlVal "_day_off_${count}"
            done
            echo "# Bye bye... !" >> ${logFile} &
            ssudo shutdown -h now
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

nanoconf()
{
    nano $DIR/config/_private.yml
}
