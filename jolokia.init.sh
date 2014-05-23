#!/bin/bash

# chkconfig: 2345 20 80
# description: Jolokia service

. /etc/init.d/functions
ulimit -c 0



if [ -r /lib/lsb/init-functions ]; then
    . /lib/lsb/init-functions
else
    exit 1
fi
DISTRIB_ID=`lsb_release -i -s 2>/dev/null`
if [ -z "${NAME}" ] ; then
	NAME="$(basename $0)"
fi
unset ISBOOT
if [ "${NAME:0:1}" = "S" -o "${NAME:0:1}" = "K" ]; then
    NAME="${NAME:3}"
    ISBOOT="1"
fi
TOMCAT_CFG="/etc/sysconfig/jolokia"
if [ -r "$TOMCAT_CFG" ]; then
    . $TOMCAT_CFG
fi
if [ -f "/etc/sysconfig/jolokia" ]; then
    . /etc/sysconfig/jolokia
fi
CONNECTOR_PORT="${CONNECTOR_PORT:-8080}"
TOMCAT_SCRIPT="sh -x ${CATALINA_BASE}/bin/catalina.sh"
TOMCAT_PROG="${NAME}"
SUBSYS="${CATALINA_BASE}/logs/${NAME}.subsys"        
TOMCAT_USER="${TOMCAT_USER:-tomcat}"

if [ -x "/sbin/runuser" ]; then
    SU="/sbin/runuser -s /bin/sh - ${TOMCAT_USER}"
else
    SU="/bin/su -s /bin/sh - ${TOMCAT_USER}"
fi
if [ `whoami` != root ] ; then
    SU=/bin/sh
fi

TOMCAT_LOG="${TOMCAT_LOG:-${CATALINA_HOME}/logs/${NAME}-initd.log}"
RETVAL="0"
function findFreePorts() {
    local isSet1="false"
    local isSet2="false"
    local isSet3="false"
    local lower="8000"
    randomPort1="0"
    randomPort2="0"
    randomPort3="0"
    local -a listeners="( $(
                        netstat -ntl | \
                        awk '/^tcp/ {gsub("(.)*:", "", $4); print $4}'
                    ) )"
    while [ "$isSet1" = "false" ] || \
          [ "$isSet2" = "false" ] || \
          [ "$isSet3" = "false" ]; do
        let port="${lower}+${RANDOM:0:4}"
        if [ -z `expr " ${listeners[*]} " : ".*\( $port \).*"` ]; then
            if [ "$isSet1" = "false" ]; then
                export randomPort1="$port"
                isSet1="true"
            elif [ "$isSet2" = "false" ]; then
                export randomPort2="$port"
                isSet2="true"
            elif [ "$isSet3" = "false" ]; then
                export randomPort3="$port"
                isSet3="true"
            fi
        fi
    done
}
function makeHomeDir() {
    if [ ! -d "$CATALINA_HOME" ]; then
        echo "$CATALINA_HOME does not exist, creating"
        if [ ! -d "/usr/share/${NAME}" ]; then
            mkdir /usr/share/${NAME}
            cp -pLR /usr/share/tomcat/* /usr/share/${NAME}
        fi
        mkdir -p /var/log/${NAME} \
                 /var/cache/${NAME} \
                 /var/tmp/${NAME}
        ln -fs /var/cache/${NAME} ${CATALINA_HOME}/work
        ln -fs /var/tmp/${NAME} ${CATALINA_HOME}/temp
        cp -pLR /usr/share/${NAME}/bin $CATALINA_HOME
        cp -pLR /usr/share/${NAME}/conf $CATALINA_HOME
        ln -fs /usr/share/java/tomcat ${CATALINA_HOME}/lib
        ln -fs /usr/share/tomcat/webapps ${CATALINA_HOME}/webapps
        chown ${TOMCAT_USER}:${TOMCAT_USER} /var/log/${NAME}
    fi
}
function parseOptions() {
    options=""
    options="$options $(
                 awk '!/^#/ && !/^$/ { ORS=" "; print "export ", $0, ";" }' \
                 $TOMCAT_CFG
             )"
    if [ -r "/etc/sysconfig/${NAME}" ]; then
        options="$options $(
                     awk '!/^#/ && !/^$/ { ORS=" "; 
                                           print "export ", $0, ";" }' \
                     /etc/sysconfig/${NAME}
                 )"
    fi
    TOMCAT_SCRIPT="$options ${TOMCAT_SCRIPT}"
}
function start() {
  
   echo -n "Starting ${TOMCAT_PROG}: "
   if [ "$RETVAL" != "0" ]; then 
     log_failure_msg
     return
   fi
   if [ -f "${SUBSYS}" ]; then
        if [ -s "/var/run/${NAME}.pid" ]; then
            read kpid < /var/run/${NAME}.pid
            if [ -d "/proc/${kpid}" ]; then
                log_success_msg
                if [ "$DISTRIB_ID" = "MandrivaLinux" ]; then
                    echo
                fi
                return 0
            fi
        fi
    fi
    # fix permissions on the log and pid files
    if [ -z "${CATALINA_PID}" ] ; then
        export CATALINA_PID="/var/run/${NAME}.pid"
    fi
    touch $CATALINA_PID 2>&1 || RETVAL="4"
    if [ "$RETVAL" -eq "0" -a "$?" -eq "0" ]; then 
      chown ${TOMCAT_USER}:${TOMCAT_USER} $CATALINA_PID
    fi
    [ "$RETVAL" -eq "0" ] && touch $TOMCAT_LOG 2>&1 || RETVAL="4" 
    if [ "$RETVAL" -eq "0" -a "$?" -eq "0" ]; then
      chown ${TOMCAT_USER}:${TOMCAT_USER} $TOMCAT_LOG
    fi
    parseOptions
    if [ "$RETVAL" -eq "0" -a "$SECURITY_MANAGER" = "true" ]; then
        $SU -c "${TOMCAT_SCRIPT} start-security" \
            >> ${TOMCAT_LOG} 2>&1 || RETVAL="4"
    else
        
       [ "$RETVAL" -eq "0" ] && $SU -c "${TOMCAT_SCRIPT} start" >> ${TOMCAT_LOG} 2>&1 || RETVAL="4"
    fi
    if [ "$RETVAL" -eq "0" ]; then 
        log_success_msg
        touch $SUBSYS
    else
        log_failure_msg "Error code ${RETVAL}"
    fi
    if [ "$DISTRIB_ID" = "MandrivaLinux" ]; then
        echo
    fi
}
function stop() {
    echo -n "Stopping ${TOMCAT_PROG}: "
    if [ -f "${SUBSYS}" ]; then
      parseOptions
      if [ "$RETVAL" -eq "0" ]; then
         touch ${SUBSYS} 2>&1 || RETVAL="4"
         [ "$RETVAL" -eq "0" ] && $SU -c "${TOMCAT_SCRIPT} stop" >> ${TOMCAT_LOG} 2>&1 || RETVAL="4"
      fi
      if [ "$RETVAL" -eq "0" ]; then
         count="0"
         if [ -s "/var/run/${NAME}.pid" ]; then
            read kpid < /var/run/${NAME}.pid
            until [ "$(ps --pid $kpid | grep -c $kpid)" -eq "0" ] || \
                      [ "$count" -gt "$SHUTDOWN_WAIT" ]; do
                    if [ "$SHUTDOWN_VERBOSE" = "true" ]; then
                        echo "waiting for processes $kpid to exit"
                    fi
                    sleep 1
                    let count="${count}+1"
                done
                if [ "$count" -gt "$SHUTDOWN_WAIT" ]; then
                    if [ "$SHUTDOWN_VERBOSE" = "true" ]; then
                        log_warning_msg "killing processes which did not stop after ${SHUTDOWN_WAIT} seconds"
                    fi
                    kill -9 $kpid
                fi
                log_success_msg
            fi
            rm -f ${CATALINA_PID}
        else
            log_failure_msg
            RETVAL="4"
        fi
    else
        log_success_msg
        RETVAL="0"
    fi
    if [ "$DISTRIB_ID" = "MandrivaLinux" ]; then
        echo
    fi
}
function usage()
{
   echo "Usage: $0 {start|stop|restart|condrestart|try-restart|reload|force-reload|status|version}"
   RETVAL="2"
}
RETVAL="0"
case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        start
        ;;
    condrestart|try-restart)
        if [ -s "/var/run/${NAME}.pid" ]; then
            stop
            start
        fi
        ;;
    reload)
        RETVAL="3"
        ;;
    force-reload)
        if [ -s "/var/run/${NAME}.pid" ]; then
            stop
            start
        fi
        ;;
    status)
        if [ -s "/var/run/${NAME}.pid" ]; then
            read kpid < /var/run/${NAME}.pid
            if [ -d "/proc/${kpid}" ]; then
                log_success_msg "${NAME} (pid ${kpid}) is running..."
                RETVAL="0"
            else
               log_warning_msg "PID file exists, but process is not running"
               RETVAL="1"
            fi
        else
            pid="$(/usr/bin/pgrep -d , -u ${TOMCAT_USER} -G ${TOMCAT_USER} java)"
            if [ -z "$pid" ]; then
                log_success_msg "${NAME} is stopped"
                RETVAL="3"
            else
                log_success_msg "${NAME} (pid $pid) is running..."
                RETVAL="0"
            fi
        fi
         if [ -f ${SUBSYS} ]; then
            pid="$(/usr/bin/pgrep -d , -u ${TOMCAT_USER} -G ${TOMCAT_USER} java)"
            if [ -z "$pid" ]; then
               log_failure_msg "${NAME} lockfile exists but process is not running"
               RETVAL="2"
            fi
         fi
        ;;
    version)
        ${TOMCAT_SCRIPT} version
        ;;
    *)
      usage
      ;;
esac
exit $RETVAL
