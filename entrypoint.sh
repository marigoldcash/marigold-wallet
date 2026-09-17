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
    # Docker makes it root's. Hand it to the account it is meant for.
    uid=${MARIGOLD_UID:-1000}
    gid=${MARIGOLD_GID:-1000}
    chown "$uid:$gid" "$DIR" 2>/dev/null || true
fi
# An explicit choice still wins.
uid=${MARIGOLD_UID:-$uid}
gid=${MARIGOLD_GID:-$gid}
export HOME=/data
exec setpriv --reuid="$uid" --regid="$gid" --clear-groups /usr/local/bin/marigold-cli "$@"
