# Discount codes, gift codes and referrals

Languages: **English** · [فارسی](promotions.fa.md) · [Русский](promotions.ru.md) · [中文](promotions.zh.md)

All three are set on the admin web's **Codes** page. A customer uses them
in the bot and in the web app; nothing about them reaches the panel.

## Discount codes

A code takes a **percent** or an **amount** off one order. It can be
limited to:

- **a window**: a start date, an end date, or both;
- **a number of uses** across all customers (0 is unlimited), and **once
  per customer** (on by default);
- **products**: some of them, or every product;
- **kinds of purchase**: new services, renewals, more traffic.

The customer types the code before choosing: the bot's list has an **I
have a discount code** button, the web app's buy page a **Have a discount
code?** link. The list then shows each product's price with the code; a
product the code does not cover keeps its price and is bought without it.
A code that does not apply is refused with the reason: unknown, off, not
started, expired, used up, not for that product or that kind of purchase,
already used by this customer.

**Holds.** An order placed with a code and not yet paid holds one of the
code's uses for **24 hours**, so the last use is never handed to two
buyers at once and never kept by one who walked away. A cancelled order
gives its use back at once; a hold that lapses is released. An order paid
after its hold lapsed is still honoured at the price the customer was
shown, and counted — so a late payment can take a code one past its limit.

An order a code makes free is paid at once and its service made; no money
moves. A code is never in the wallet's ledger: the order simply asks less.
Deleting a code that orders carried switches it off instead; those orders
keep its name.

## Gift codes

A gift code puts an **amount** in the customer's wallet — for a
promotion, or to make up for something — **once per customer**, within an
optional end date and number of uses. In the bot it is on the wallet
screen (**Gift code**), in the web app on the Wallet page. Whatever the
wallet then covers is paid at once: a customer with an unpaid order can
pay it with a gift. Discount and gift codes share one namespace — a
customer types a code without saying which kind it is.

## Referrals

Every customer has their own referral link, shown once referrals are on:

- the bot's: `https://t.me/<bot>?start=ref_<code>` (the menu's **Invite
  friends**);
- the web app's: `https://<shop>/app/?ref=<code>` (the Wallet page).

A customer who **first** comes by a link belongs to that referrer for
good: the referral is bound when the customer is made, and nothing moves
it after — not another referrer's link, not the admin. A customer who was
already the shop's when they opened a link stays nobody's. When a Telegram
customer and a web customer are joined, the one staying keeps their own
referral; one who never bought and was nobody's takes the other's — the
same person's first start.

The reward, set under **Referrals**:

- **a percent of each order** the referred customer pays — or, with **the
  percent on the first order only**, of the first one;
- **a fixed amount on the first order**, in the shop's currency;
- both, or neither (both zero: referrals are off and no link is shown).

It goes to the referrer's wallet **when the panel has made the order**,
not when it is merely paid — an order the panel refuses is refunded — and
the referrer is told in the bot. A trial or an order a code made free pays
nothing. A refund of the order takes the reward back, as far as the
referrer's wallet still holds it. The **first order** is the first one the
panel made with money in it; a refunded first order still counts as the
first.

## The API

The admin's routes, signed in:

| Route | What it does |
| --- | --- |
| `GET /api/discounts` | every discount code, with its uses, the uses held now, and its state |
| `POST /api/discounts`, `PUT /api/discounts/{id}` | create, edit — a field left out keeps its value |
| `DELETE /api/discounts/{id}` | delete; one that orders carried is switched off |
| `GET /api/discounts/{id}/redemptions` | the orders it was put on |
| `GET`/`POST /api/gifts`, `PUT`/`DELETE /api/gifts/{id}` | the same for gift codes |
| `GET`/`PUT /api/settings/referral` | `percent`, `firstOnly`, `fixed` |
| `GET /api/referrals` | the rewards paid, newest first |

The customers' routes (`/api/c`, bearer token): `POST /quote` (`code`,
`kind`) answers what the code takes off each product; `POST /orders` takes
a `code`; `POST /gift` spends a gift code; `GET /referral` is the
customer's links and earnings. A refused code answers **422** with a
`reason`. The sign-ins (`/login/verify`, `/login/telegram`) take the
link's `ref`; the mini-app also reads `ref_<code>` from its start
parameter (`t.me/<bot>?startapp=ref_<code>`).
