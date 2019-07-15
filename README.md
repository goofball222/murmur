# Murmur Docker Container

[![Docker Build Status](https://img.shields.io/docker/cloud/build/goofball222/murmur.svg)](https://hub.docker.com/r/goofball222/murmur/) [![Docker Pulls](https://img.shields.io/docker/pulls/goofball222/murmur.svg)](https://hub.docker.com/r/goofball222/murmur/) [![Docker Stars](https://img.shields.io/docker/stars/goofball222/murmur.svg)](https://hub.docker.com/r/goofball222/murmur/) [![MB Layers](https://images.microbadger.com/badges/image/goofball222/murmur.svg)](https://microbadger.com/images/goofball222/murmur) [![MB Commit](https://images.microbadger.com/badges/commit/goofball222/murmur.svg)](https://microbadger.com/images/goofball222/murmur) [![MB License](https://images.microbadger.com/badges/license/goofball222/murmur.svg)](https://microbadger.com/images/goofball222/murmur)

## Docker tags:
| Tag | Murmur Version | Description | Release Date |
| --- | :---: | --- | :---: |
| [latest](https://github.com/goofball222/murmur/blob/master/stable/Dockerfile) | 1.2.19 | Latest stable release | 2018-08-24 |
| [rc](https://github.com/goofball222/murmur/blob/master/rc/Dockerfile) | 1.3.0-rc2 | Latest release candidate | 2019-06-25 |
| [release-1.2.19](https://github.com/goofball222/murmur/releases/tag/1.2.19) | 1.2.19 | Static stable release tag/image | 2018-03-01 |

---

* [Recent changes, see: GitHub CHANGELOG.md](https://github.com/goofball222/murmur/blob/master/CHANGELOG.md)
* [Report any bugs, issues or feature requests on GitHub](https://github.com/goofball222/murmur/issues)

---

## Usage

This container exposes four volumes:
* `/opt/murmur/cert` - Murmur SSL certificate files
* `/opt/murmur/config` - Murmur configuration files
* `/opt/murmur/data` - Murmur database and other data files
* `/opt/murmur/log` - Murmur log for troubleshooting


This container exposes two ports:
* `64738/tcp` Murmur server TCP port
* `64738/udp` Murmur server UDP port

---

**The most basic way to run this container:**

```bash
$ docker run --name murmur -d \
    -p 64738:64738/udp -p 64738:64738 \
    goofball222/murmur
```

---

**Recommended: run via [Docker Compose](https://docs.docker.com/compose/):**

Have the container store the config & logs on a local file-system or in a specific, known data volume (recommended for persistence and
 troubleshooting):


```bash

version: '3'

services:
  murmur:
    image: goofball222/murmur
    container_name: murmur
    ports:
      - 64738:64738
      - 64738:64738/udp
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - ./cert:/opt/murmur/cert
      - ./config:/opt/murmur/config
      - ./data:/opt/murmur/data
      - ./log:/opt/murmur/log
    environment:
      - TZ=UTC

```

[Example `docker-compose.yml` file](https://raw.githubusercontent.com/goofball222/murmur/master/examples/docker-compose.yml)

---

**Environment variables:**

| Variable | Default | Description |
| :--- | :---: | --- |
| `DEBUG` | ***false*** | Set to *true* for extra entrypoint script verbosity for debugging |
| `MURMUR_OPTS` | ***unset*** | Any additional custom run flags for the container murmur.x86 process |
| `PGID` | ***999*** | Specifies the GID for the container internal murmur group (used for file ownership) |
| `PUID` | ***999*** | Specifies the UID for the container internal murmur user (used for process and file ownership) |
| `RUN_CHOWN` | ***true*** | Set to *false* to disable the container automatic `chown` at startup. Speeds up startup process on overlay2 Docker hosts. **NB/IMPORTANT:** It's critical that you insure directory/data permissions on all mapped volumes are correct before disabling this or murmur will not start. |
| `BASEDIR` | ***/opt/murmur*** | Base directory for Murmur |
| `CERTDIR` | ***/opt/murmur/cert*** | Directory for Murmur SSL certificate files |
| `CONFIGDIR` | ***/opt/murmur/config*** | Directory for Murmur configuration files |
| `DATADIR` | ***/opt/murmur/data*** | Directory for Murmur database and other data files |
| `LOGDIR` | ***/opt/murmur/log*** | Directory for Murmur log for troubleshooting |

---

**SSL custom certificate support ([LetsEncrypt](https://letsencrypt.org/), etc.):**

1. Map the Docker host cert storage location or volume to the `/opt/murmur/cert` volume exposed by the container
2. Must contain a PEM format SSL private key corresponding to the SSL certificate to be installed.
Private key file **MUST** be named `privkey.pem`.
3. Must contain a PEM format SSL certificate file with the full certification chain. LetsEncrypt handles this automatically, other providers may need manual work (https://www.digicert.com/ssl-support/pem-ssl-creation.htm).
Certificate file **MUST** be named `fullchain.pem`.
4. Start the container. sslCert and sslKey paths in murmur.ini are updated automatically during startup if SSL certificate files are detected. Status, errors, etc. can be found in the container log, IE: `docker logs <containername>`

If you don't want to use a custom SSL certificate then the `/opt/murmur/cert` volume can be left unmapped. Alternatively if the `privkey.pem` and/or `fullchain.pem` file are not present SSL customization will be skipped.

To revert from a custom cert to a Murmur self-signed certificate: stop the container, rename or remove both privkey.pem and fullchain.pem from `/DATA_VOLUME/murmur/cert`. Then edit the murmur.ini file in `/DATA_VOLUME/murmur/config` and change the lines `sslCert=/opt/murmur/cert/fullchain.pem` to `;sslCert=` & `sslKey=/opt/murmur/cert/privkey.pem` to `;sslKey=`, save the file, and restart the container.


[//]: # (Licensed under the Apache 2.0 license)
[//]: # (Copyright 2018 The Goofball - goofball222@gmail.com)
