# CopyParty LazyCat community package

Upstream https://github.com/9001/copyparty (MIT), image `copyparty/ac:1.20.26`. Package `community.lazycat.app.copyparty`, min OS 1.5.0, amd64, mirror delivery, community (喵喵) store only. The official `cloud.lazycat.app.copyparty` entry is a separate build.

Single Python container, no database. Shared files live in one bind:

    /lzcapp/var/data:/w

Unlike upstream's basic example, which shares the webroot with `r: *` (everyone), this package is closed by default: the `/` volume grants `rwmd` only to the single account from the deployment parameters, so an unauthenticated request can read nothing.

Credentials are not baked into the image or shipped in a config file. `content/start.sh` validates them (username restricted to `[A-Za-z0-9_.@-]`, secret at least 12 characters from a fixed safe set, since the config format has no escaping), renders a config into tmpfs at `/run/copyparty`, `chmod 600`, and then execs copyparty. It fails closed with a message that never echoes the value.

No `public_path` and no file-picker interception, per the project's standing rules for this batch; the app stays behind the platform entry login.

Not device-tested: login, upload/download, resumable uploads, thumbnails, media indexing, WebDAV mount, and persistence across restarts.
