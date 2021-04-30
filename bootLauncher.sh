#!/bin/bash

#
# Spring Boot embedd WAS launcher v1.210501
#

USER="wasuser"

# Java environments
export JAVA_HOME="/app/jdk-11"
export JAVA="/app/jdk-11/bin/java"

# Process name 
PROC_NAME="demo"

# Jar File Path
SVCPATH="/svcroot/runtime/webapps/springboot/"
JAR_FILE="demo-0.0.1-SNAPSHOT.jar"

# Loggin path
LOG_PATH="/app/was/springboot/log"
STDOUT_FILE="${LOG_PATH}/stdout.log"
PID_PATH="/app/was/springboot/log"
PROC_PID_FILE="${PID_PATH}/${PROC_NAME}.pid"

# Java option
JVM_OPTION="-Djava.security.egd=file:///dev/urandom"

# deploy envrionment
PROFILE="dev"


userchk()
{
        if [ $(id -un) != ${USER} ];then
                echo "Please run ${wasuser}"
                exit 0
        fi
}

get_status()
{
    ps ux | grep ${JAR_FILE} | grep -v grep | awk '{print $2}'
}

status()
{
    local PID=$(get_status)
    if [ -n "${PID}" ]; then
        echo 0
    else
        echo 1
    fi
}

start()
{
    if [ $(status) -eq 0 ]; then
        echo "${PROC_NAME} is already running"
        exit 0
    else
        nohup ${JAVA} -jar ${JVM_OPTION} ${SVCPATH}${JAR_FILE} >> ${STDOUT_FILE} 2>&1 &
        if [ $(status) -eq 1 ];then 
            echo "${PROC_NAME} is start ... [Failed]"
            exit 1
        else
            echo "${PROC_NAME} is start ... [OK]"
            local PID=$(get_status)
            echo ${PID} > ${PROC_PID_FILE}
        fi
    fi
}

stop()
{
    # verify pid
    if [ ! -e ${PROC_PID_FILE} ];then
        PID=$(get_status)
    else
        PID=$(cat "${PROC_PID_FILE}")
    fi

    # If no have pid file and no have running process then PID set zero manual
    [ Z"${PID}" == Z ] && PID=0

    if [ "${PID}" -lt 3 ]; then
        echo "${PROC_NAME} was not running."
    else
        kill ${PID}
        rm -f ${PROC_PID_FILE}
        if [ $(status) -eq 0 ];then
                echo "${PROC_NAME} is shutdown ... [OK]"
        else
                echo "${PROC_NAME} is shutdown ... [Failed]"
        fi
    fi
}

case "$1" in
        start)
                userchk
                start
                sleep 1
        ;;
        stop)
                userchk
                stop
                sleep 1
        ;;
        restart)
                userchk
                stop
                sleep 2
                start
        ;;
        status)
                if [ $(status) -eq 0 ]; then
                    echo "${PROC_NAME} is running"
                else
                    echo "${PROC_NAME} is stopped"
                fi
        ;;
        *)
                echo "Useage : $0 {start | stop | restart | status}"
        ;;
esac
