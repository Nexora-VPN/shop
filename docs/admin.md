# The admin web

Languages: **English** · [فارسی](admin.fa.md) · [Русский](admin.ru.md) · [中文](admin.zh.md)

Shop's admin is at its own address (`https://<shop>/`), in English,
Persian, Russian and Chinese. Everything Shop does is operated from here;
nothing needs `curl`.

| Page | What it is for |
| --- | --- |
| **Dashboard** | today's and the last 30 days' sales, receipts waiting for a person, failed orders, customers and what their wallets hold; the panel Shop is registered with; new sales paused because the panel has no room ([reopen them](../README.md#when-the-panel-has-no-room)), accounts that no longer match the panel; and a warning when the panel gives customers subscription links on its admin base path — only the panel's own subscription base path (**Subscription base path** in the panel's **Settings**) hides it; a subscription domain or a public address changes the host, not the path |
| **Orders** | every purchase with who bought what; refund a failed or fulfilled one to the wallet, cancel an unpaid one; a paid order whose panel call **stopped** (unanswered too long) is sent again with **Send again** — a renewal or traffic only after you checked the panel does not show it — or refunded |
| **Receipts** | card-to-card receipts to approve or reject (the same queue as the Telegram topic) |
| **Customers** | find a customer by name, Telegram id, email or phone; open one to edit their details, credit or pay out their wallet, read their statement, see their services and place an order for them |
| **Agents** | levels and agents ([agents](agents.md)) |
| **Reports** | sales per period and currency, new against renewal, the renewal rate, top products and agents, what codes, gifts, referrals and refunds cost, what the wallets hold |
| **Products** | new services from a panel plan, renewals (days or calendar months, optional traffic and cycle reset), more traffic; prices per currency; take one off sale |
| **Payment methods** | cards, generic gateways with their health, the payment settings, the bank-SMS forwarder's address and secret, the SMS received |
| **Codes and referrals** | discount codes, gift codes, the referral reward ([promotions](promotions.md)) |
| **Bot texts** | every message the bot sends, in each language turned on, in your own words (below) |
| **Settings** | the bot (currency, trial, channel to join first, top-up amounts, support, reminders, the trials' clean-up, auto-renew), the customers' languages, whether Shop reminds at all ([or the notifier](../README.md#reminders-or-the-notifier)), the language of the posts to your admins' chat, broadcasts, sign-in by email and by SMS |
| **Set-up** | the checklist that gets a new Shop selling ([portal](portal.md)) |
| **Security** | your password and two-step sign-in |
| **Backup** | the schedule, the archives, the key, and the check after a panel restore ([backup](backup.md)) |

## The bot's texts

Each of the bot's messages and buttons, in each language turned on, can be
replaced. A text is a Go template over the values its step provides —
shown as chips under the editor, `{{.Name}}`, `{{.Amount}}` and so on — and
may use those and no others; the editor previews it with sample values and
Shop checks it before keeping it, so a mistake cannot reach a customer. The
bot uses a saved text at once. Clearing a text, or **Back to the built-in**,
returns to Shop's own wording, which a later release may improve. Messages
use Telegram's HTML: `<b>`, `<i>`, `<code>`, `<a href="…">`.

## The reports

A **sale** is an order paid in the chosen window and not refunded; a trial
is not a sale. The **renewal rate** is the share of the accounts sold before
the window — not trials, still on the panel — that were renewed or topped
up within it. **Held in wallets** is what the shop owes its customers right
now. Money is shown per currency and never converted.
