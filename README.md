# Nexora Shop

The official [Nexora](https://nexora-panel.org) addon that sells a panel's
plans: products, orders, a wallet, payments and a Telegram bot.

> **This release is the skeleton.** It installs, registers with a panel,
> updates and uninstalls exactly as Shop will; it sells nothing yet. The store
> arrives in the next releases.

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

## Files

| File | What it is |
| --- | --- |
| [`nexora-addon.json`](nexora-addon.json) | the manifest, signed by Nexora; the directory and the panel read it here |
| [`install.sh`](install.sh) | install, update or remove on a Linux host |
| [`deploy/compose.yml`](deploy/compose.yml) | the stack the docker method runs |

Releases carry the binaries for `linux-amd64` and `linux-arm64` with their
`SHA256SUMS`. Shop is free and closed-source — see [LICENSE](LICENSE).
