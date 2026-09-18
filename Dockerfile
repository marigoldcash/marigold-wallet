# The Marigold wallet, ready to run.
#
# The binary is fetched from this repository's releases rather than built here:
# the source repository is private for now, and a tester should not need access
# to it to try the wallet. When the source opens, this becomes a normal build.
FROM debian:trixie-slim

# ca-certificates for wss:// to a public node; nothing else is needed — the
# wallet is a single static-ish binary and the node it can run is inside it.
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates \
 && rm -rf /var/lib/apt/lists/*

ARG VERSION=v0.2.31
ARG REPO=marigoldcash/marigold_docker
ADD https://github.com/${REPO}/releases/download/${VERSION}/marigold-cli /usr/local/bin/marigold-cli
RUN chmod 0755 /usr/local/bin/marigold-cli

# Not root. This process handles keys that ARE money, and a container that runs
# as root gives a bug in it the run of the filesystem it can reach.
# 0755 on the home directory, not useradd's default 0700. The compose file
# runs the container as the invoking user so that files written into the
# mounted ~/.marigold stay owned by that person — and a 0700 /data owned by
# uid 10001 means any other uid cannot even traverse into it to reach the
# mount. Nothing sensitive lives in /data itself; the wallet is in the mount.
RUN useradd --create-home --home-dir /data --uid 10001 marigold \
 && chmod 0755 /data
COPY entrypoint.sh /usr/local/bin/marigold-entrypoint
RUN chmod 0755 /usr/local/bin/marigold-entrypoint
WORKDIR /data
# The container starts as root only long enough for the entrypoint to see who
# owns the mounted ~/.marigold and become that user; the wallet itself never
# runs as root. See entrypoint.sh.
ENV HOME=/data
ENTRYPOINT ["/usr/local/bin/marigold-entrypoint"]
