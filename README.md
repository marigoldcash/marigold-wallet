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

**On an Apple Silicon Mac** the compose file pins `platform: linux/amd64`, so
Docker runs the image under emulation. That is deliberate: the released binary
is x86-64, and without the pin the container exits with `exec format error`
before the wallet prints anything. Everything works; only the wallet's own node
is noticeably slower. A native arm64 build is on the list.

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

Back it up from inside the wallet:

```
wallet backup /data/marigold-backup.mgb
```

That writes everything — the wallet, the note vault, every note key — into one
file, encrypted under a passphrase you choose there and then. It is safe to
keep somewhere you do not control: a cloud drive, a chat with yourself, a USB
stick that is not yours. `wallet restore <file>` rebuilds it anywhere, and it
needs that passphrase and nothing else.

The file lands in the volume, so copy it out:

```sh
docker run --rm -v marigold-data:/data -v "$PWD:/out" debian:trixie-slim \
  cp /data/marigold-backup.mgb /out/
```

Anyone with that file and its passphrase can spend your money. Treat it as
cash — which is what it is.

Do not rely on the 24 words alone. They unlock the vault, they are not a copy
of it: with the words and no files you can recover your ledger balance and
**none of your notes**. Nothing can derive a note, which is exactly what makes
it cash. Lose the notes and they are gone, with no recovery and nobody to
appeal to.

## Running your own node

The wallet has a full node built in:

```
node start
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
