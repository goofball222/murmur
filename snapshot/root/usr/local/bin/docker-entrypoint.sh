#!/usr/bin/env bash

# Init script for Murmur server Docker container
# License: Apache-2.0
# Github: https://github.com/goofball222/murmur.git
SCRIPT_VERSION="1.0.1"
# Last updated date: 2018-08-24

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

do_chown() {
    if [ "${RUN_CHOWN}" == 'false' ]; then
        if [ ! "$(stat -c %u ${BASEDIR})" = "${PUID}" ] || [ ! "$(stat -c %u ${CONFIGDIR})" = "${PUID}" ] \
        || [ ! "$(stat -c %u ${LOGDIR})" = "${PUID}" ]; then
            log "WARN - Configured PUID doesn't match owner of a required directory. Ignoring RUN_CHOWN=false"
            log "INFO - Ensuring permissions are correct before continuing - 'chown -R murmur:murmur ${BASEDIR}'"
            log "INFO - Running recursive 'chown' on Docker overlay2 storage is **really** slow. This may take a bit."
            chown -R murmur:murmur ${BASEDIR}
        else
            log "INFO - RUN_CHOWN set to 'false' - Not running 'chown -R murmur:murmur ${BASEDIR}', assume permissions are right."
        fi
    else
        log "INFO - Ensuring permissions are correct before continuing - 'chown -R murmur:murmur ${BASEDIR}'"
        log "INFO - Running recursive 'chown' on Docker overlay2 storage is **really** slow. This may take a bit."
        chown -R murmur:murmur ${BASEDIR}
    fi
}


murmur_setup() {
    log "INFO - Insuring murmur.ini setup for container"
    if [ ! -e ${CONFIGDIR}/murmur.ini ]; then
        log "WARN - '${CONFIGDIR}/murmur.ini' doesn't exist, copying from '${BASEDIR}/murmur.ini-default'"
        cp -p ${BASEDIR}/murmur.ini-default ${CONFIGDIR}/murmur.ini
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

    MURMUR_OPTS="${MURMUR_OPTS} -fg -v -ini ${CONFIGDIR}/murmur.ini"
}

exit_handler() {
    log "INFO - Exit signal received, commencing shutdown"
    pkill -15 -f ${MURMUR}
    for i in `seq 0 9`;
        do
            [ -z "$(pgrep -f ${MURMUR})" ] && break
            # kill it with fire if it hasn't stopped itself after 9 seconds
            [ $i -gt 8 ] && pkill -9 -f ${MURMUR} || true
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
        if [ "$(id murmur -g)" != "${PGID}" ] || [ "$(id murmur -u)" != "${PUID}" ];
            then
                log "INFO - Setting custom murmur GID/UID: GID=${PGID}, UID=${PUID}"
                groupmod -o -g ${PGID} murmur
                usermod -o -u ${PUID} murmur
            else
                log "INFO - GID/UID for murmur are unchanged: GID=${PGID}, UID=${PUID}"
        fi

        if [[ "${@}" == 'murmur' ]];
            then
                murmur_setup
                do_chown
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
        log "WARN - Unable to change permissions or set custom GID/UID if configured"
        log "WARN - Process will be spawned with GID=$(id -g), UID=$(id -u)"
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
