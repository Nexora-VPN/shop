# Nexora Shop

The official [Nexora](https://nexora-panel.org) addon that sells a panel's
plans: products, orders, a wallet, card-to-card and gateway payments, a
Telegram bot, a web app, discount and gift codes, referrals and agents.

Languages: **English** · [فارسی](docs/fa.md) · [Русский](docs/ru.md) · [中文](docs/zh.md)

## Install

From the panel (recommended): **Services → Addons → Browse**, pick
**Nexora Shop**, answer the questions, and either let the panel install it on
a host over SSH or run the command it gives you. The panel registers Shop by
itself once its health check answers.

By hand, on a Linux host, as root:

```sh
curl -fsSLO https://raw.githubusercontent.com/Nexora-VPN/shop/main/install.sh
sh install.sh --method script --opt port=8095 --panel-url https://your-panel --claim-code XXXX-XXXX-XXXX-XXXX
```

| Method | What runs |
| --- | --- |
| `--method script` | the binary under the systemd unit `nexora-addon-shop` |
| `--method docker` | the compose stack in [`deploy/compose.yml`](deploy/compose.yml) (`ghcr.io/nexora-vpn/shop`) |

Everything lives in `/opt/nexora-addons/shop`: the answers in `.env`, the data
in `data/`.

- **Update:** run `sh install.sh` again (or **Update on its host** in the
  panel). The answers and the data are kept.
- **Remove:** `sh install.sh --uninstall`, with `--purge` to delete the data.

| Option | Default | |
| --- | --- | --- |
| `port` | `8095` | the port Shop listens on |
| `database` | `sqlite` | `sqlite` keeps everything in `data/`; `postgres` uses a server you run |
| `database_dsn` | | PostgreSQL's connection (asked only for `postgres`) |
| `admin_username` | `admin` | Shop's own admin account |
| `admin_password` | | its password, at least 10 characters; used once to make the account — change it in Shop afterwards |
| `base_path` | drawn | the path Shop's admin, its API and the panel's calls are under; customers' pages (`/app/`, `/pay/`) stay at the root and never show it. The panel and `install.sh` draw a random one; `base_path=` (empty) puts the admin at the root. An update keeps what the install has |
| `https` | `off` | `acme`: a certificate for the public address's domain, on 443; `self-signed`: Shop's own, for an address by IP (browsers warn, Telegram's mini-app does not open); `off`: none, or your own proxy |

Then open Shop's admin at its address and its base path — `install.sh`
prints it, the panel opens it from the addon's row — and follow **Set-up**:
the bot, the public address, a payment method and the first product.

## Guides

| Guide | What it covers |
| --- | --- |
| [The admin web](docs/admin.md) | every page, the bot's texts, the reports |
| [Payments](docs/payments.md) | card-to-card with receipts and the bank's SMS, the generic gateway, exchange rates |
| [The web app](docs/portal.md) | the portal and the Telegram mini-app, sign-in by email, SMS or the bot |
| [Codes and referrals](docs/promotions.md) | discount codes, gift codes, the referral reward |
| [Agents](docs/agents.md) | levels, prepaid agents, their statement |
| [Backup and restore](docs/backup.md) | Shop's own encrypted backup, moving to a new host, after a panel restore |

## Customers' languages

Shop speaks Persian, English, Russian and Chinese. Under **Settings**, turn
on the ones your customers use. Each customer is served in their own — the
language of their Telegram, or the one they pick in the bot or the web app —
when it is on, otherwise in English, or in the first language on. A
product's form asks a name in each language turned on; a name left empty
shows another language's. Turning a language off moves its customers to the
nearest one on. The bot's texts can be reworded in each language (**Bot
texts**).

## Reminders, or the notifier

By default Shop tells customers about their accounts: its own reminders
before expiry and the panel's warnings — expiring, expired, traffic used or
used up, renewed or deleted on the panel. If you run the
[notifier](https://github.com/Nexora-VPN/notif), which does this for every
account on the panel, turn **Shop tells customers about expiry, traffic,
renewals and deletions** off under **Settings**, so nobody hears it twice.
What Shop does itself — a purchase, a receipt, the wallet, an automatic
renewal that the wallet could not pay — is still told by Shop.

## When the panel has no room

Shop checks no licence of its own: the panel does. When the panel refuses a
new account because its licence is full, Shop owns up to it plainly: the
order's money goes back to the customer's wallet at once, the customer is
told why, your admins' Telegram topic is told with the panel's own words,
and new services and trials pause for an hour so the next customers are not
taken in by the same refusal. Renewals and more traffic go on. Upgrade the
panel's licence or make room, then press **Reopen sales** on the dashboard.

## Files

| File | What it is |
| --- | --- |
| [`nexora-addon.json`](nexora-addon.json) | the manifest, signed by Nexora; the directory and the panel read it here |
| [`install.sh`](install.sh) | install, update or remove on a Linux host |
| [`deploy/compose.yml`](deploy/compose.yml) | the stack the docker method runs |

Releases carry the binaries for `linux-amd64` and `linux-arm64` with their
`SHA256SUMS`, and `SHA256SUMS.sig`, Nexora's signature over it: the panel
installs Shop over SSH only when `install.sh` and the binary match it. Shop is free and closed-source — see [LICENSE](LICENSE).
