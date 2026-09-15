# Marigold wallet — Docker

Digital cash in fixed-denomination bearer notes. This repository packages the
wallet so you can try it without building anything.

**Testnet only.** The money is worthless by design and the network may be reset
without notice.

## Run it

```sh
mkdir -p ~/.marigold
curl -fsSLO https://raw.githubusercontent.com/marigoldcash/marigold_docker/main/docker-compose.yml
docker compose run --rm wallet
```

If that prints nothing, it worked. GitHub's CDN occasionally answers with a
503 page, and without `-f` curl saves the error page *as* `docker-compose.yml`
— you then get a YAML parse error that has nothing to do with the file. Run it
again if it complains.

That is the whole install. The first run builds a small image — it downloads a
binary, nothing is compiled — and drops you at the wallet prompt.

**On an Apple Silicon Mac** the compose file pins `platform: linux/amd64`, so
Docker runs the image under emulation. That is deliberate: the released binary
is x86-64, and without the pin the container exits with `exec format error`
before the wallet prints anything. Everything works; only the wallet's own node
is noticeably slower. A native arm64 build is on the list.

Then, in the wallet, type what the note tells you to: `wallet create` the
first time, `open` after that. The wizard asks one question worth a pause —
**Keep a ledger account too? [Y/n]** — and shows you twenty-four words once.
Then `connect`.

`connect` reaches a node we run, so there is nothing else to set up. Get some
testnet money at <https://faucet.marigold.cash>, and type `guide` for a
walkthrough that reads the state of your wallet and only tells you what
applies to you.

The prompt shows what you hold in notes, and only that:

```
marigold • 12.30 TMAGLD in notes ›
```

`balance` has the rest.

## Notes only, or with a ledger

Most people never need the ledger. Notes are paid and received directly:
`note request` prints a code for whoever is paying you, `note pay` pays one
you were shown, and `exchange <address> <amount>` pays anyone who only has an
address, straight from your notes in one transaction. Answer **n** to the
wizard's question and the wallet has a vault and nothing else — no ledger
address is ever derived.

A ledger is for two things: mining, and being paid by an exchange that only
pays to an address. Keep one (the default), or add it later with
`account create bip32` — it comes from the same twenty-four words, so there
is nothing extra to back up.

Without a ledger there is nowhere to put change, so `exchange` needs notes
that make up the amount to within 0.01. The wallet says so when they do not.

## The technical side, off by default

```
advanced on
```

Off, the wallet reads like a wallet: `help` lists the everyday commands, no
address is printed unasked, and an error is one plain line that says what to
do next. On, `help` lists every command, addresses appear where they belong,
and the reason behind an error is printed in full. `advanced off` puts it
back; the choice is remembered.

## Your notes live in `~/.marigold`

The same folder the native wallet uses, so there is one set of keys on this
machine rather than two. It holds your wallet file and your note vault — **which
is your money** — in an ordinary directory you can see, copy, and include in
whatever you already back up.

The container runs as your own user so the files stay yours. If your account is
not uid 1000, tell it:

```sh
MARIGOLD_UID=$(id -u) MARIGOLD_GID=$(id -g) docker compose run --rm wallet
```

Sharing the folder is safe. The wallet takes an exclusive lock on whichever
wallet file it opens, held by the kernel on the real file — so a wallet already
open on the host refuses to open in the container, and the other way round. You
get a plain message, not a corrupted wallet.

**Your wallet is one directory.** A wallet used to be a file with two folders
beside it; it is now a single `NAME.wallet/` holding the keys, the notes and
the history — one thing to copy, not three. The wallet does this itself the
first time it opens, by renaming inside the same folder, so it is instant
however much history there is.

**Upgrading from v0.2.1 or earlier?** Your wallet was in a Docker volume at
`/var/lib/docker/volumes/marigold-data/_data`. Move it into the open — this
never overwrites a wallet you already have, it renames the incoming one:

```sh
mkdir -p ~/.marigold
docker run --rm -v marigold-data:/from -v "$HOME/.marigold:/to" debian:trixie-slim sh -c '
  cd /from/.marigold 2>/dev/null || exit 0
  for w in *.wallet; do
    [ -e "$w" ] || continue
    n=${w%.wallet}
    t=$n
    if [ -e "/to/$n.wallet" ]; then t="$n-docker-migrated"; echo "renaming $n -> $t (a wallet called $n is already there)"; fi
    cp -a "$w" "/to/$t.wallet"
    [ -d "$n.notes" ] && cp -a "$n.notes" "/to/$t.notes"
    [ -d "$n.transactions" ] && cp -a "$n.transactions" "/to/$t.transactions"
    echo "migrated $n as $t"
  done'
sudo chown -R "$(id -u):$(id -g)" ~/.marigold
```

Check your wallets are there with `wallet list` before running
`docker volume rm marigold-data`. Anything renamed can be put back with
`wallet rename` once you have decided which is which.

Back it up from inside the wallet:

```
wallet backup /data/marigold-backup.mgb
```

That writes everything — the wallet, the note vault, every note key — into one
file, encrypted under a passphrase you choose there and then. It is safe to
keep somewhere you do not control: a cloud drive, a chat with yourself, a USB
stick that is not yours. `wallet restore <file>` rebuilds it anywhere, and it
needs that passphrase and nothing else.

The file lands in `~/.marigold/marigold-backup.mgb`, on your own disk — nothing
to copy out of a volume.

Anyone with that file and its passphrase can spend your money. Treat it as
cash — which is what it is.

Do not rely on the 24 words alone. They unlock the vault, they are not a copy
of it: with the words and no files you can recover your ledger balance and
**none of your notes**. Nothing can derive a note, which is exactly what makes
it cash. Lose the notes and they are gone, with no recovery and nobody to
appeal to.

## Asking for a code before it spends

```
otp on
```

Enrols an authenticator app on your phone. After that, every spend, export or
handover wants a six-digit code as well as your password.

It protects a wallet that is already **open** — the machine you walked away
from, the terminal someone else sits down at. It does not protect the wallet
file: the code's secret lives inside that file under the same password, so
whoever has both can generate their own codes. Your password and your
twenty-four words are still what stands between a thief and your money.

Turning it off takes a current code, or your twenty-four vault words if the
phone is gone.

## Mining with spare CPU

If you are running the wallet's own node (below), it can mine:

```
mine start
```

It asks what share of the machine to use and defaults to half. The threads run
at the lowest priority the system has, so they stand aside the moment you do
anything else. `mine status` for the speed and what it has found.

This needs your own node. Asking a public node for work would tell its
operator which address your coins are paid to.

## Running your own node

The wallet has a full node built in. `connect` offers it, and `node start`
starts it by hand:

```
node start
```

Nobody then sees your address or which notes you hold — with a public node, the
operator does. It takes a while to catch up and several gigabytes of disk. See
<https://marigold.cash/faq> for what that choice actually costs.

Once you have chosen your own node, the wallet remembers. The next time you
open and say yes to **Connect now?**, it starts the node, says it is no use
until it has caught up, and asks once whether to use a public node in the
meantime. It never connects to a public node unasked.

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
