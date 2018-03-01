#!/usr/bin/env bash

# Init script for Murmur server Docker container
# License: Apache-2.0
# Github: https://github.com/goofball222/murmur.git
SCRIPT_VERSION="0.0.1"
# Last updated date: 2018-03-01

set -Eeuo pipefail

if [ "${DEBUG}" == 'true' ];
    then
        set -x
fi

log() {
    echo "$(date -u +%FT$(nmeter -d0 '%3t' | head -n1)) <docker-entrypoint> $*"
}

log "INFO - Script version ${SCRIPT_VERSION}"

BASEDIR="/opt/murmur"
CERTDIR=${BASEDIR}/cert
CONFIGDIR=${BASEDIR}/config
DATADIR=${BASEDIR}/data
LOGDIR=${BASEDIR}/log

MURMUR=${BASEDIR}/murmur.x86

MURMUR_OPTS="${MURMUR_OPTS}"

cd ${BASEDIR}

murmur_setup() {
    log "INFO - Insuring murmur.ini setup for container"
    if [ ! -e ${CONFIGDIR}/murmur.ini ]; then
        log "WARN - '${CONFIGDIR}/murmur.ini' doesn't exist, copying from '${BASEDIR}/murmur.ini-default'"
        cp ${BASEDIR}/murmur.ini-default ${CONFIGDIR}/murmur.ini
    fi

    sed -i '/database=/c\database='"${DATADIR}"'/murmur.sqlite' ${CONFIGDIR}/murmur.ini

    sed -i '/logfile=murmur.log/c\logfile='"${LOGDIR}"'/murmur.log' ${CONFIGDIR}/murmur.ini

    if [ -e ${CERTDIR}/privkey.pem ] && [ -e ${CERTDIR}/fullchain.pem ]; then
        sed -i '/sslCert=/c\sslCert='"${CERTDIR}"'/fullchain.pem' ${CONFIGDIR}/murmur.ini
        sed -i '/sslKey=/c\sslKey='"${CERTDIR}"'/privkey.pem' ${CONFIGDIR}/murmur.ini
    else
        [ -f ${CERTDIR}/privkey.pem ] || log "WARN - SSL: missing '${CERTDIR}/privkey.pem', murmur will use self-signed SSL certificate"
        [ -f ${CERTDIR}/fullchain.pem ] || log "WARN - SSL: missing '${CERTDIR}/fullchain.pem', murmur will use self-signed SSL certificate"
    fi

    sed -i '/uname=/c\uname=murmur' ${CONFIGDIR}/murmur.ini

    log "INFO - Ensuring file permissions for murmur user/group - 'chown -R murmur:murmur ${BASEDIR}'"
    chown -R murmur:murmur ${BASEDIR}

    MURMUR_OPTS="${MURMUR_OPTS} -fg -v -ini ${CONFIGDIR}/murmur.ini"
}

exit_handler() {
    log "INFO - Exit signal received, commencing shutdown"
    pkill -15 -f ${BASEDIR}/murmur.x86
    for i in `seq 0 9`;
        do
            [ -z "$(pgrep -f ${BASEDIR}/murmur.x86)" ] && break
            # kill it with fire if it hasn't stopped itself after 9 seconds
            [ $i -gt 8 ] && pkill -9 -f ${BASEDIR}/murmur.x86 || true
            sleep 1
    done
    log "INFO - Shutdown complete. Nothing more to see here. Have a nice day!"
    log "INFO - Exit with status code ${?}"
    exit ${?};
}

# Wait indefinitely on tail until killed
idle_handler() {
    while true
    do
        tail -f /dev/null & wait ${!}
    done
}

trap 'kill ${!}; exit_handler' SIGHUP SIGINT SIGQUIT SIGTERM

if [ "$(id -u)" = '0' ];
    then
        log "INFO - Entrypoint running with UID 0 (root)"
        if [ "$(id murmur -u)" != "${PUID}" ] || [ "$(id murmur -g)" != "${PGID}" ];
            then
                log "INFO - Setting custom murmur UID/GID: UID=${PUID}, GID=${PGID}"
                usermod -u ${PUID} murmur && groupmod -g ${PGID} murmur
            else
                log "INFO - UID/GID for murmur are unchanged: UID=${PUID}, GID=${PGID}"
        fi

        if [[ "${@}" == 'murmur' ]];
            then
                murmur_setup

                log "EXEC - ${MURMUR} ${MURMUR_OPTS}"
                exec 0<&-
                exec ${MURMUR} ${MURMUR_OPTS} &
                idle_handler
            else
                log "EXEC - ${@} as UID 0 (root)"
                exec "${@}"
        fi
    else
        log "WARN - Container/entrypoint not started as UID 0 (root)"
        log "WARN - Unable to change permissions or set custom UID/GID if configured"
        log "WARN - Process will be spawned with UID=$(id -u), GID=$(id -g)"
        log "WARN - Depending on permissions requested command may not work"
        if [[ "${@}" == 'murmur' ]];
            then
                murmur_setup
                exec 0<&-
                log "EXEC - ${MURMUR} ${MURMUR_OPTS}"
                exec ${MURMUR} ${MURMUR_OPTS} &
                idle_handler
            else
                log "EXEC - ${@}"
                exec "${@}"
        fi
fi

# Script should never make it here, but just in case exit with a generic error code if it does
exit 1;
