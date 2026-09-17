# downloads/

Serves APK downloads for the Raasel Android app. Binaries here are
gitignored (too large for git) — the real `raasel.apk` lives only on the
production server and is bind-mounted over this folder at runtime (see
`docker-compose.yml`), not baked into the image.

To publish a new build: `scp` the APK to `/opt/raasel.org/downloads/` on
Contabo. No container rebuild or restart needed — nginx serves it
directly from the mounted host folder.
