# Marigold wallet — Docker

Digital cash in fixed-denomination bearer notes. This repository packages the
wallet so you can try it without building anything.

**Testnet only.** The money is worthless by design and the network may be reset
without notice.

## Run it

```sh
curl -O https://raw.githubusercontent.com/marigoldcash/marigold_docker/main/docker-compose.yml
docker compose run --rm wallet
```

That is the whole install. The first run builds a small image — it downloads a
binary, nothing is compiled — and drops you at the wallet prompt.

Then, in the wallet:

```
network testnet
wallet create
connect
```

`connect` reaches a node we run, so there is nothing else to set up. Get some
testnet money at <https://faucet.marigold.cash>.

## Your notes live in a Docker volume

`marigold-data`. It holds your wallet file and your note vault — **which is your
money**. It survives `docker compose down`. It does not survive
`docker volume rm marigold-data`.

Back it up:

```sh
docker run --rm -v marigold-data:/data -v "$PWD:/backup" debian:trixie-slim \
  tar czf /backup/marigold-backup.tgz -C /data .marigold
```

Better still, run `note vault backup` in the wallet and keep the 24 words
somewhere a fire will not reach. A copied file protects you from a mistake; the
words protect you from a dead disk. Marigold notes are bearer instruments —
lose them and they are gone, with no recovery and nobody to appeal to.

## Running your own node

The wallet has a full node built in:

```
mynode start
```

Nobody then sees your address or which notes you hold — with a public node, the
operator does. It takes a while to catch up and several gigabytes of disk. See
<https://marigold.cash/faq> for what that choice actually costs.

The compose file publishes port 26211 so your node can accept peers.

## What is in the image

`debian:trixie-slim`, CA certificates, and the wallet binary from this
repository's [releases](https://github.com/marigoldcash/marigold_docker/releases).
It runs as an unprivileged user, not root.

The wallet's source is not public yet. When it is, this image will be built from
source rather than from a published binary.

## Links

- [Litepaper](https://marigold.cash/litepaper/)
- [Questions](https://marigold.cash/faq)
- [Faucet](https://faucet.marigold.cash)
