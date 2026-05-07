# herald

**A small Linux daemon and CLI that prints a quote at the top of every new terminal and at login. Cached quote refreshed on a configurable timer. Local fallback pool. Optional user prefix.**

## Quick install (Debian / Ubuntu)

One line. Sets up the signed `ra-yavuz` apt repo if not already added, refreshes the package index, and installs herald. Idempotent, safe to re-run:

```bash
sudo bash -c 'set -e; install -m 0755 -d /etc/apt/keyrings && curl -fsSL https://ra-yavuz.github.io/apt/pubkey.gpg -o /etc/apt/keyrings/ra-yavuz.gpg && echo "deb [signed-by=/etc/apt/keyrings/ra-yavuz.gpg] https://ra-yavuz.github.io/apt stable main" > /etc/apt/sources.list.d/ra-yavuz.list && apt update && apt install -y herald'
```

Or via the bundled installer script (equivalent, with prerequisite checks and a friendlier output summary):

```bash
curl -fsSL https://raw.githubusercontent.com/ra-yavuz/herald/main/scripts/get.sh | sudo bash
```

Both forms add the [signed apt repository](https://ra-yavuz.github.io/apt/) (if not already added), run `apt update`, and install the package. Future upgrades: `sudo apt update && sudo apt upgrade`. Full removal: `sudo apt purge herald`.

If you already have the `ra-yavuz` apt repo, all you need is `sudo apt update && sudo apt install herald`. The `sudo apt update` step is required: without it apt will not see new packages or new versions.

> ## Disclaimer / no warranty
>
> herald is provided **as is, without warranty of any kind**, express or implied, including but not limited to merchantability, fitness for a particular purpose, and noninfringement. By installing or running this software you accept that:
>
> - Quotes are fetched from a third-party service (zenquotes.io). The author of this software does not control, curate, or vouch for the content of fetched quotes. If a quote is offensive or inappropriate, that is on the upstream service. Disable online fetching with `sudo herald set-refresh 0` and rely on the bundled local pool only.
> - The author is **not liable** for any harm, data loss, hardware failure, or other damages, however caused.
> - The author is not liable for events outside their control: third-party API outage, supply-chain compromise, modifications made downstream after distribution.
> - You alone are responsible for any consequence of installing or running this software.

## What it does

Two display surfaces, both off by default:

1. **Terminal greeting:** every new interactive shell (terminal tab/window in your desktop session, or a fresh shell anywhere) prints today's quote at the top. Implemented via `/etc/profile.d/50-herald.sh` plus a small marker block injected into the invoking user's `~/.bashrc` (since `/etc/bash.bashrc` on Ubuntu does not source profile.d). dpkg owns the file; `apt purge` removes it cleanly.

2. **Login MOTD:** at SSH login, console login, or display-manager login, today's quote is shown in the login banner. Implemented via `/etc/update-motd.d/95-herald`. This requires the `update-motd` package on Debian/Ubuntu (Suggests, not Recommends, so laptop-only users don't pull it in by default; the CLI warns at runtime if you enable MOTD without it).

Toggle them independently:

```bash
sudo herald terminal on        # eye candy: every new terminal
sudo herald motd on            # login banner: SSH / console / DM login
sudo herald all on             # both
sudo herald all off            # neither
herald status                  # show what's enabled
```

## Quote source and refresh

Online: [zenquotes.io](https://zenquotes.io) (free, no API key, well-behaved). Each refresh hits the API once with a 1.5s timeout. If that fails, falls back to a bundled local pool of ~30 curated quotes (`/usr/share/herald/quotes.json`) so the tool always works offline.

Refresh cadence: every **3 hours** by default. Configurable in hours:

```bash
sudo herald set-refresh 24     # once a day
sudo herald set-refresh 168    # once a week
sudo herald set-refresh 1      # hourly
sudo herald set-refresh 0      # disable timer; manual refresh only
sudo herald refresh            # force a refresh now
```

Implementation: a systemd timer (`herald-refresh.timer`) writes a cached JSON object at `/var/cache/herald/today.json`. The terminal greeting and the MOTD entry both read from the cache, so login/shell startup is fast and offline-friendly.

## Optional prefix

Want to prepend custom text above the quote (a hostname banner, contact info, etc.)?

```bash
sudo herald set-prefix "Welcome to tripolis. Coffee, then code."
sudo herald clear-prefix
```

The text is stored at `/etc/herald.prefix` and printed verbatim above the quote.

## Status

```bash
$ herald status
Refresh:    every 3 hours
Timer:      active
Cache:      /var/cache/herald/today.json
  fetched:  2026-05-05T14:30:00Z
  source:   zenquotes
Prefix:     none
Terminal:   enabled
MOTD:       disabled
```

## Sample output

```
$ herald
  "Premature optimization is the root of all evil."
    -- Donald Knuth
```

With a prefix set:

```
Welcome to tripolis. Coffee, then code.

  "Premature optimization is the root of all evil."
    -- Donald Knuth
```

## Install paths

### Debian / Ubuntu via apt repo (recommended)

See the one-liner at the top. Step by step (manual repo setup):

```bash
# 1. Trust the signing key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://ra-yavuz.github.io/apt/pubkey.gpg \
  | sudo tee /etc/apt/keyrings/ra-yavuz.gpg > /dev/null

# 2. Add the apt source
echo "deb [signed-by=/etc/apt/keyrings/ra-yavuz.gpg] https://ra-yavuz.github.io/apt stable main" \
  | sudo tee /etc/apt/sources.list.d/ra-yavuz.list

# 3. Refresh the package index, then install
sudo apt update
sudo apt install herald
```

### Debian / Ubuntu single .deb

```bash
wget https://github.com/ra-yavuz/herald/releases/latest/download/herald_0.1.0-1_all.deb
sudo apt install ./herald_0.1.0-1_all.deb
```

### From source

```bash
git clone https://github.com/ra-yavuz/herald.git
cd herald
sudo bash install.sh
```

## How it integrates with other ra-yavuz tools

herald is fully independent. It does not know about, depend on, or modify any other tool. If you also have `inhibit-charge` installed and have its terminal greeting enabled, you'll see both lines in every new terminal: the inhibit-charge battery state, then the herald quote. They share the same `/etc/profile.d/` directory but each file short-circuits independently.

## Removing

```bash
sudo apt purge herald          # if installed via apt
sudo bash install.sh purge     # if installed from source
```

`purge` (apt or script) wipes `/var/cache/herald/`, `/etc/herald.prefix`, `/etc/herald.conf`, and the timer override file. The bashrc block is removed only by `herald terminal off`; if you've already purged the package and still see the block, remove it by hand from `~/.bashrc`.

## License

MIT. See `LICENSE`.
