#!/bin/sh
# Run the wallet as whoever owns ~/.marigold on the host, so the files it
# writes stay theirs and the files already there can be read.
#
# The image used to hard-code uid 1000. On Linux that is usually right; on a
# Mac the first account is 501, Docker Desktop shows the folder inside the
# container with that real owner, and a wallet running as 1000 could not read
# it — "Permission denied" on 'wallet list' was a tester's first experience.
#
# Started as root, this script looks at the folder, becomes its owner, and
# runs the wallet. Started as anyone else (docker run -u, or a 'user:' line in
# a compose file), it runs the wallet as that user and changes nothing.
set -e
DIR=/data/.marigold
if [ "$(id -u)" != "0" ]; then
    exec /usr/local/bin/marigold-cli "$@"
fi
mkdir -p "$DIR"
uid=$(stat -c %u "$DIR")
gid=$(stat -c %g "$DIR")
if [ "$uid" = "0" ]; then
    # Docker made the folder itself because it did not exist on the host, and
    # Docker makes it root's. The wallet is the user's, so the folder must be
    # theirs — but a container cannot see who that is. The compose file can:
    # it mounts itself here, read-only, and whoever fetched it is the person
    # running the wallet. Their real uid shows through the mount.
    PROBE=/run/marigold/owner
    if [ -e "$PROBE" ] && [ "$(stat -c %u "$PROBE")" != "0" ]; then
        uid=$(stat -c %u "$PROBE")
        gid=$(stat -c %g "$PROBE")
    else
        uid=1000
        gid=1000
        echo "marigold: created ~/.marigold as uid $uid. If that is not you, stop now and run:" >&2
        echo "  MARIGOLD_UID=\$(id -u) MARIGOLD_GID=\$(id -g) docker compose run --rm wallet" >&2
    fi
    chown "$uid:$gid" "$DIR" 2>/dev/null || true
fi
# An explicit choice still wins.
uid=${MARIGOLD_UID:-$uid}
gid=${MARIGOLD_GID:-$gid}
export HOME=/data
exec setpriv --reuid="$uid" --regid="$gid" --clear-groups /usr/local/bin/marigold-cli "$@"
