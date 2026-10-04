# Backup and restore

Languages: **English** · [فارسی](backup.fa.md) · [Русский](backup.ru.md) · [中文](backup.zh.md)

The money is in Shop's database and the accounts are in the panel's, so
there are two databases to keep. The panel backs up its own; Shop backs up
its own, here.

## What a backup is

An archive of Shop's database — a consistent copy, taken while Shop runs —
and the card-to-card receipts, encrypted with a key only you keep. Under
**Backup** in Shop's admin:

| Setting | Default | |
| --- | --- | --- |
| Every how many hours | `24` | `0` turns the schedule off |
| Archives kept on the host | `7` | older ones are deleted |
| Send a copy off the host | on | to the panel's backup chat, or through Shop's bot |

Archives are written into `data/backups/` as `shop-<date>-<time>.nxsb`, and
each can be downloaded from the same page. **Back up now** takes one at once.

**The copy off the host** goes to the Telegram chat you chose for backups on
the panel (**Services → Backup destinations → Telegram**), through the
panel's own bot — Shop never sees that chat. When that is off on the panel,
the copy goes through Shop's bot to each admin paired with it. Telegram
takes files up to 50 MB: a larger archive stays on the host and the page
says so. The panel cannot read an archive; neither can Telegram.

On **PostgreSQL** the database is yours and so is its backup: `pg_dump`, like
the rest of that server. Shop's archives then hold the receipts only, and
say so.

## The key

**Show the key** under **Backup** shows the key that opens every archive
(`nxsb-…`). Copy it somewhere safe, away from this server: an archive opens
with it and nothing else, and a lost server takes its copy of the key with
it. The key does not change; an archive made with it opens with it forever.

## Moving to a new host

1. Install Shop on the new host as usual, and stop it
   (`systemctl stop nexora-addon-shop`, or `docker compose stop shop`).
2. Copy an archive there and put it back with the key:

   ```sh
   nexora-shop restore -i shop-20261004-120000.nxsb -key nxsb-…
   ```

   With docker: `docker compose run --rm shop restore -i /data/backups/shop-….nxsb -key nxsb-…`
   (copy the archive into `data/backups/` first).
3. Start Shop again.

The restore checks the key and that the database inside is Shop's before it
touches anything, and keeps what it replaced as `shop.db.before-restore` and
`receipts.before-restore`. A wrong key or a damaged archive changes nothing.
The panel's registration is not in the archive: if the new host keeps the
old address, copy `data/nexora-credentials.json` along; otherwise remove
Shop from the panel's Addons page and register it again.

`nexora-shop backup` takes an archive by hand, with the same key.

## After a panel restore

When the panel is restored from a backup, its accounts are as they were
then — and what Shop sold since may be gone from it. The panel tells Shop
(`panel.restore_applied`), and Shop checks every account it sold against
the panel. An account the panel no longer has, or whose date or traffic is
behind what Shop's last order left it with, is listed under **Backup →
After a panel restore**, with the order that paid for it, and the dashboard
says how many are open. Settle each by hand — renew it on the panel, or
refund the order — and mark it **Settled**. **Check now** runs the same
check at any time.
