#!/usr/bin/env bash

# docker-entrypoint.sh script for Murmur Docker container
# License: Apache-2.0
# Github: https://github.com/goofball222/murmur.git
SCRIPT_VERSION="1.1.0"
# Last updated date: 2020-07-16

set -Eeuo pipefail

if [ "${DEBUG}" == 'true' ];
    then
        set -x
fi

. /usr/local/bin/entrypoint-functions.sh

BASEDIR="/opt/murmur"
CERTDIR=${BASEDIR}/cert
CONFIGDIR=${BASEDIR}/config
DATADIR=${BASEDIR}/data
LOGDIR=${BASEDIR}/log

MURMUR=${BASEDIR}/murmur.x86

MURMUR_OPTS="${MURMUR_OPTS}"

f_log "INFO - Entrypoint script version ${SCRIPT_VERSION}"
f_log "INFO - Entrypoint functions version ${ENTRYPOINT_FUNCTIONS_VERSION}"

cd ${BASEDIR}

f_exit_handler() {
    f_log "INFO - Exit signal received, commencing shutdown"
    pkill -15 -f ${MURMUR}
    for i in `seq 0 9`;
        do
            [ -z "$(pgrep -f ${MURMUR})" ] && break
            # kill it with fire if it hasn't stopped itself after 9 seconds
            [ $i -gt 8 ] && pkill -9 -f ${MURMUR} || true
            sleep 1
    done
    f_log "INFO - Shutdown complete. Nothing more to see here. Have a nice day!"
    f_log "INFO - Exit with status code ${?}"
    exit ${?};
}

# Wait indefinitely on tail until killed
f_idle_handler() {
    while true
    do
        tail -f /dev/null & wait ${!}
    done
}

trap 'kill ${!}; f_exit_handler' SIGHUP SIGINT SIGQUIT SIGTERM

if [ "$(id -u)" = '0' ]; then
    f_log "INFO - Entrypoint running with UID 0 (root)"
    if [[ "${@}" == 'murmur' ]]; then
        f_giduid
        f_setup
        f_chown
        f_log "EXEC - ${MURMUR} ${MURMUR_OPTS}"
        exec 0<&-
        exec ${MURMUR} ${MURMUR_OPTS} &
        f_idle_handler
    else
        f_log "EXEC - ${@} as UID 0 (root)"
        exec "${@}"
    fi
else
    f_log "WARN - Container/entrypoint not started as UID 0 (root)"
    f_log "WARN - Unable to change permissions or set custom GID/UID if configured"
    f_log "WARN - Process will be spawned with GID=$(id -g), UID=$(id -u)"
    f_log "WARN - Depending on permissions requested command may not work"
    if [[ "${@}" == 'murmur' ]];
        then
            f_setup
            exec 0<&-
            f_log "EXEC - ${MURMUR} ${MURMUR_OPTS}"
            exec ${MURMUR} ${MURMUR_OPTS} &
            f_idle_handler
        else
            f_log "EXEC - ${@}"
            exec "${@}"
    fi
fi

# Script should never make it here, but just in case exit with a generic error code if it does
exit 1;
