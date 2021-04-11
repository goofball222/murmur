#!/usr/bin/env bash

# entrypoint-functions.sh script for Murmur Docker container
# License: Apache-2.0
# Github: https://github.com/goofball222/murmur.git
ENTRYPOINT_FUNCTIONS_VERSION="1.2.0"
# Last updated date: 2021-04-11

f_chown() {
    if [ "${RUN_CHOWN}" == 'false' ]; then
        if [ ! "$(stat -c %u ${BASEDIR})" = "${PUID}" ] || [ ! "$(stat -c %u ${CONFIGDIR})" = "${PUID}" ] \
        || [ ! "$(stat -c %u ${LOGDIR})" = "${PUID}" ]; then
            f_log "WARN - Configured PUID doesn't match owner of a required directory. Ignoring RUN_CHOWN=false"
            f_log "INFO - Ensuring permissions are correct before continuing - 'chown -R murmur:murmur ${BASEDIR}'"
            f_log "INFO - Running recursive 'chown' on Docker overlay2 storage is **really** slow. This may take a bit."
            chown -R murmur:murmur ${BASEDIR}
        else
            f_log "INFO - RUN_CHOWN set to 'false' - Not running 'chown -R murmur:murmur ${BASEDIR}', assume permissions are right."
        fi
    else
        f_log "INFO - Ensuring permissions are correct before continuing - 'chown -R murmur:murmur ${BASEDIR}'"
        f_log "INFO - Running recursive 'chown' on Docker overlay2 storage is **really** slow. This may take a bit."
        chown -R murmur:murmur ${BASEDIR}
    fi
}

f_giduid() {
    if [ "$(id murmur -g)" != "${PGID}" ] || [ "$(id murmur -u)" != "${PUID}" ]; then
        f_log "INFO - Setting custom murmur GID/UID: GID=${PGID}, UID=${PUID}"
        groupmod -o -g ${PGID} murmur
        usermod -o -u ${PUID} murmur
    else
        f_log "INFO - GID/UID for murmur are unchanged: GID=${PGID}, UID=${PUID}"
    fi
}

f_log() {
    echo "$(date -u +%FT$(nmeter -d0 '%3t' | head -n1)) <docker-entrypoint> $*"
}

f_setup() {
    f_log "INFO - Insuring murmur.ini setup for container"
    if [ ! -e ${CONFIGDIR}/murmur.ini ]; then
        f_log "WARN - '${CONFIGDIR}/murmur.ini' doesn't exist, copying from 'etc/murmur.ini'"
        cp -p /etc/murmur.ini ${CONFIGDIR}/murmur.ini
    fi

    sed -i '/database=/c\database='"${DATADIR}"'/murmur.sqlite' ${CONFIGDIR}/murmur.ini

    sed -i '/logfile=murmur.log/c\logfile='"${LOGDIR}"'/murmur.log' ${CONFIGDIR}/murmur.ini

    if [ -e ${CERTDIR}/privkey.pem ] && [ -e ${CERTDIR}/fullchain.pem ]; then
        sed -i '/sslCert=/c\sslCert='"${CERTDIR}"'/fullchain.pem' ${CONFIGDIR}/murmur.ini
        sed -i '/sslKey=/c\sslKey='"${CERTDIR}"'/privkey.pem' ${CONFIGDIR}/murmur.ini
    else
        [ -f ${CERTDIR}/privkey.pem ] || f_log "WARN - SSL: missing '${CERTDIR}/privkey.pem', murmur will use self-signed SSL certificate"
        [ -f ${CERTDIR}/fullchain.pem ] || f_log "WARN - SSL: missing '${CERTDIR}/fullchain.pem', murmur will use self-signed SSL certificate"
    fi

    sed -i '/uname=/c\uname=murmur' ${CONFIGDIR}/murmur.ini

    MURMUR_OPTS="${MURMUR_OPTS} -fg -v -ini ${CONFIGDIR}/murmur.ini"

    MURMUR_SUPW=${MURMUR_SUPW:-}
    if [ ! -z "${MURMUR_SUPW}" ]; then
        f_log "CRIT - MURMUR_SUPW is configured, changing superuser password via command line."
        f_log "CRIT - Use MURMUR_SUPW *once* to set a new superuser password and then restart without it."
        f_log "CRIT - ** SERVER WILL NOT FULLY START OR ACCEPT CONNECTIONS WITH MURMUR_SUPW SET **"
        MURMUR_OPTS="${MURMUR_OPTS} -supw ${MURMUR_SUPW}"
    fi

}

