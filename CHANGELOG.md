* **2020-07-16:**
    * Split docker-entrypoint.sh into main script and functions script.
    * Add MURMUR_SUPW variable to allow for command line superuser password set/change.
    * Delete rc and snapshot directories
---
* **2020-07-09:**
    * Update stable to 1.3.2 release - https://dl.mumble.info/stable/?C=M;O=D - https://github.com/mumble-voip/mumble/releases/tag/1.3.2
    * Update Dockerfile label schema
---
* **2020-06-10:**
    * Update stable to 1.3.1 release - https://dl.mumble.info/?C=M;O=D
---
* **2019-09-08:**
    * Update stable to 1.3.0 release - https://dl.mumble.info/?C=M;O=D
---
* **2019-06-28:**
    * Update rc to 1.3.0-rc2 - https://dl.mumble.info/?C=M;O=D
---
* **2019-03-27:**
    * Clone master:snapshot to master:rc, update to 1.3.0-rc1 - https://dl.mumble.info/?C=M;O=D
---
* **2019-03-14:**
    * Update master:snapshot to 1.3.0~2961~g1ee050a~snapshot - https://dl.mumble.info/?C=M;O=D
---
* **2019-02-26:**
    * Update master:snapshot to 1.3.0~2942~g755c290~snapshot - https://dl.mumble.info/?C=M;O=D
---
* **2019-02-11:**
    * Update master:snapshot to 1.3.0~2935~gc176974~snapshot - https://dl.mumble.info/?C=M;O=D
---
* **2018-10-04:**
    * Update master:snapshot to 1.3.0~2872~gb44b1f2~snapshot - https://dl.mumble.info/?C=M;O=D
---
* **2018-09-13:**
    * Update master:snapshot to 1.3.0~2870~gf7221c1~snapshot - https://dl.mumble.info/?C=M;O=D
---
* **2018-08-24:**
    * Update Dockerfile
        * Shh, be vewy vewy quiet, I'm hunting errors in the build logs. (Add -q to Dockerfile apk commands)
        * Rework post-build cleanup
        * Add support for RUN_CHOWN flag
        * Add tzdata package
    * docker-entrypoint.sh
        * Add support for RUN_CHOWN flag
        * Add -o flag to groupmod/usermod - allow setting custom GID/UID when already exists
    * Update documentation
    * Update build hook script
---
* **2018-06-14:**
    * Update Dockerfile to remove depreciated "MAINTAINER", move info to LABEL "vendor" value
---
* **2018-04-05:**
    * Update master:snapshot to 1.3.0~2729~g2126495~snapshot - https://wiki.mumble.info/wiki/Main_Page
---
* **2018-03-31:**
    * Add Alpine "shadow" packge to Dockerfile to support usermod/groupmod in docker-entrypoint.sh for changing process UID/GID.
---
* **2018-03-28:**
    * Update master:snapshot to 1.3.0~2723~g109ddd4~snapshot - https://wiki.mumble.info/wiki/Main_Page
---
* **2018-03-19:**
    * Update master:snapshot to 1.3.0~2717~gb25db3e~snapshot - https://wiki.mumble.info/wiki/Main_Page
---
* **2018-03-01:**
    * Initial Dockerfile, script, etc. creation.
