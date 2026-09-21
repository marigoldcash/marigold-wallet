# Marigold wallet

Digital cash in fixed-denomination bearer notes. This repository is where you get the wallet without building anything: a binary for your machine from the [releases](https://github.com/marigoldcash/marigold-wallet/releases), or a Docker image that fetches one for you.

The wallet is built from the [Marigold source](https://github.com/marigoldcash/marigold), which is public. Every release here is cut from that code base at the same tag: v2.52.237 here is [v2.52.237 there](https://github.com/marigoldcash/marigold/tree/v2.52.237), one number for the wallet, its release and its source. And the per-platform binaries on it are built by that repository's [Wallet binaries](https://github.com/marigoldcash/marigold/actions/workflows/binaries.yaml) GitHub Actions workflow on GitHub's own Linux, Windows and macOS runners, so what you download was compiled from the source you can read, on a machine nobody here controls.

**Testnet only.** The money is worthless by design and the network may be reset
without notice.

## Run it

Two ways. The binary is the simpler one; Docker suits a machine you would rather not put a new program on.

### The binary

Download the one for your machine from the [latest release](https://github.com/marigoldcash/marigold-wallet/releases/latest). A release is named after the wallet inside it: v2.52.237 is what the front note shows and what `marigold-cli --version` prints, so you can always tell whether you are on the latest.

| File | For |
| --- | --- |
| `marigold-cli-linux-x86_64` | Linux, 64-bit Intel or AMD |
| `marigold-cli-macos-arm64` | Apple Silicon Mac |
| `marigold-cli-macos-x86_64` | Intel Mac |
| `marigold-cli-macos-universal` | Either Mac, one file, twice the size |
| `marigold-cli-windows-x86_64.exe` | Windows, 64-bit |
| `marigold-cli` | Linux x86-64 again, the build the release was cut with; it is what the Docker image fetches |

On Linux or a Mac, make it executable and run it:

```sh
chmod +x marigold-cli-linux-x86_64
./marigold-cli-linux-x86_64
```

The binaries are unsigned. A Mac stops the first launch: allow it under System Settings, Privacy and Security, then run it again. Windows shows a SmartScreen notice; More info, then Run anyway. That is the price of not paying Apple and Microsoft for certificates while this is a testnet.

The wallet keeps everything in `~/.marigold`, the same folder Docker uses, so you can switch between the two later. Then carry on at *In the wallet* below.

### Docker

```sh
mkdir -p ~/.marigold
curl -fsSLO https://raw.githubusercontent.com/marigoldcash/marigold-wallet/main/docker-compose.yml
docker compose run --rm wallet
```

If that prints nothing, it worked. GitHub's CDN occasionally answers with a
503 page, and without `-f` curl saves the error page *as* `docker-compose.yml`
— you then get a YAML parse error that has nothing to do with the file. Run it
again if it complains.

That is the whole install. The first run builds a small image — it downloads a
binary, nothing is compiled — and drops you at the wallet prompt.

**On an Apple Silicon Mac** the compose file pins `platform: linux/amd64`, so
Docker runs the image under emulation. That is deliberate: the binary in the image
is x86-64, and without the pin the container exits with `exec format error`
before the wallet prints anything. Everything works; only the wallet's own node
is noticeably slower. For full speed on a Mac, skip Docker and run the native
`marigold-cli-macos-arm64` from the release instead.

### In the wallet

Type what the note tells you to: `wallet create` the
first time, `open` after that. It asks for a name and a password, and one
question worth a pause — **Keep a ledger account too? [Y/n]**. Then
`connect`.

`connect` starts syncing a copy of the network on this machine — nobody else
then sees which notes you ask about. The first sync takes a while, and until
it has caught up nothing can be seen or paid, so the wallet asks once whether
to use a public computer meanwhile; it never does that unasked. Get some
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
`pay 20` makes a code worth 20 to hand over, `receive <code>` takes one you
were given, `request` prints a code for whoever is paying you, and
`exchange <address> <amount>` pays anyone who only has an address, straight
from your notes in one transaction. Answer **n** to the wizard's question and
the wallet has a vault and nothing else — no ledger address is ever derived.

A ledger is for two things: mining, and being paid by an exchange that only
pays to an address. Keep one (the default), or add it later with
`account create bip32` — it comes from the same twenty-four words, so there
is nothing extra to back up.

Without a ledger there is nowhere to put change, so `exchange` needs notes
that make up the amount to within 0.01. The wallet says so when they do not.

## Paying and being paid

```
pay 20
```

prints a code worth 20 — show it, send it, hand it over — and the wallet
adds a 0.01 so the receiver can make it theirs; you pay, they receive. Fewest
notes that cover it, a larger note split if needed. `pay <serial>` hands one
particular note over the same way, and `pay <request-code>` pays a request
you were shown with nothing to hand over. A code is cash: anyone who sees it
can take it, so give it straight to the receiver, who types:

```
receive <code>
```

`request` prints a code for whoever is paying you and waits for the money;
`history` lists what you have paid and received; `move 500` moves notes into
another wallet on this machine; `mobile` puts notes on your phone.

### The receipt

When you pay a request, the wallet ends with a receipt: a `marigoldreceipt:`
code, printed as text and as a QR. Give it to whoever asked for the payment. It
is a pointer, not the money and not the proof: it names the transaction, the
request it answers and the amount, so a shop can find your payment in one
lookup instead of watching the network for it. Nothing in it is secret, and
nothing in it is taken on trust — the shop still checks the chain. If the
shop has no field for it, ignore it; the payment stands on its own.

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

The container runs as whoever owns that folder on your machine, so the files
stay yours — on Linux and on a Mac alike, whatever your account's uid. If the
folder does not exist yet, Docker creates it, and the wallet hands it to the
owner of the compose file, which is you. To choose the account yourself:

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

Your password and that backup are what bring the wallet back. Nothing else
can, and there is nobody to appeal to. Prefer paper? `note vault words` prints
24 recovery words that, together with a copy of the vault files, rebuild the
wallet without the password — the words alone recover your ledger balance and
**none of your notes**, because nothing can derive a note, which is exactly
what makes it cash.

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

Once the network is synced on this machine (above), the wallet can mine:

```
mine start
```

It asks what share of the machine to use and defaults to half. The threads run
at the lowest priority the system has, so they stand aside the moment you do
anything else. `mine status` for the speed and what it has found.

This needs the sync on this machine. Asking a public computer for work would
tell its operator which address your coins are paid to.

### As a service, without the wallet open

The same binary runs as a miner on its own — no terminal, no wallet, just the network syncing on this machine and the miner paying to an address you give it:

```sh
MARIGOLD_MINE_TO=marigoldtest:your-address-here docker compose --profile miner up -d miner
docker compose logs -f miner
```

`MARIGOLD_MINE_CPU` sets the share of the machine (default 50). Take the address from `address` in your wallet. The miner waits for the sync to catch up, then mines, and logs a line a minute about how it is going. Stop it with `docker compose --profile miner down`; it stops its threads and closes the database cleanly.

A wallet started afterwards finds it: `connect` says *Found the Marigold miner running in the background on this machine* and uses its copy of the network instead of syncing a second one. From then on `mine start`, `mine stop` and `mine status` steer the background miner, and `mine status` shows where the rewards go — the address the miner was started with, which need not be this wallet's.

Without Docker, the binary from the release does the same thing:

```sh
marigold-cli mine-to marigoldtest:your-address-here 50
```

`marigold-cli --help` explains this on one screen. It stays in the foreground and logs to stdout, so systemd looks after it. [systemd/marigold-miner.service](systemd/marigold-miner.service) is a unit to copy, with the address and the share on its `ExecStart` line. The number is the share of the machine, 1 to 100, and defaults to 50. On a machine that already runs a marigoldd, add `--node grpc://127.0.0.1:26210` (a marigoldd's default RPC) and the miner uses that node instead of syncing one of its own; a wallet cannot steer it then, only the log shows how it is going.

## Paying someone who is not there yet

`receive key` makes a key of yours to hand out, like a phone number; `receive key bob` makes one just for Bob, which names him in `history` and cannot be compared with anyone else's. Whoever has your key pays you with

```
pay 5 marigoldkey:…          (three days by default; 'for 1 day', 'for 2 weeks')
```

and gives you the code it prints. The money is theirs to send and yours alone to take, with `receive` and the code, until the lock lapses; if you never take it, it comes back to them by itself. Nobody else, the payer included, can spend it in between. From the phone: `/key` for a key, `/pay 5 marigoldkey:…` to pay to one.

## Your wallet on your phone: a Telegram bot

The phone is a remote; the wallet stays at home. Make a bot of your own in Telegram (BotFather, `/newbot`, copy the token), then in your wallet:

```
mobile telegram <token>
```

It asks for a PIN the bot will want before paying, and shows a pairing code. From then on the bot is answered whenever that wallet is open: in your normal terminal session, for as long as it stays open, or with no terminal at all as a service, with the password in a file only you can read:

```sh
umask 077; echo "your wallet password" > ~/.marigold/wallet.pw
marigold-cli serve <wallet name> --password-file ~/.marigold/wallet.pw
```

Send your bot `/start <pairing code>` once. From then on, in that chat: `/balance`, `/pay 5` (asks the PIN, answers with a code to hand over), `/receive <code>` or simply paste any code you were given, `/request 5`, `/history`, `/status`. One Telegram user is paired; everyone else is ignored. There is a daily limit, 100 by default, `mobile telegram limit <amount>` changes it. Three wrong PINs lock the bot until the service restarts.

The service runs in the foreground and logs to stdout; [systemd/marigold-wallet.service](systemd/marigold-wallet.service) is a unit to copy. `--mine 50` on the same command mines to the wallet's own address too. This is a hot wallet on that machine: whoever can read the password file can spend. Turn on two-step verification in Telegram, since the paired account now moves money and Telegram accounts recover by SMS otherwise.

## The network

```
connect
```

syncs a copy of the network on this machine. Nobody then sees your address or
which notes you hold — with a public computer, its operator does. It takes a
while to catch up and several gigabytes of disk; `connect status` shows
progress, `disconnect` stops it. See <https://marigold.cash/faq> for what the
choice actually costs. `connect public` uses a public computer instead, for
whoever wants that.

The compose file publishes port 26211 so your copy of the network can accept peers.

## What is in the image

`debian:trixie-slim`, CA certificates, and the Linux wallet binary from this
repository's [releases](https://github.com/marigoldcash/marigold-wallet/releases).
It runs as an unprivileged user, not root.

The image downloads the release binary rather than compiling anything, so building it takes seconds. If you would rather build the wallet yourself, the source is at [marigoldcash/marigold](https://github.com/marigoldcash/marigold); the workflow file there shows the exact `cargo build` line the released binaries come from.

## Links

- [Source code](https://github.com/marigoldcash/marigold)
- [Litepaper](https://marigold.cash/litepaper/)
- [Questions](https://marigold.cash/faq)
- [Faucet](https://faucet.marigold.cash)
