# Agents

Languages: **English** · [فارسی](agents.fa.md) · [Русский](agents.ru.md) · [中文](agents.zh.md)

An agent («نماینده») is one of your customers who resells: it buys services
for its own customers at its **level's** price, from a wallet it tops up
first, and hands each link over itself. Set them up on the admin web's
**Agents** page.

## Levels

A level is the price for a group of agents:

- **a percent off** the shop's price of every product;
- **its own price** for any product you name, in place of the percent;
- **a referral rate**: when above zero, what an agent's referral link pays
  it of every order of the customers it brings, in place of the shop's
  referral percent (the shop's fixed first-order amount still applies —
  see [promotions](promotions.md)).

Changing a level changes the prices of every agent on it from their next
order. A level some agent is on cannot be deleted.

## Making an agent

Pick a customer (one who has started the bot or signed in to the web
app), a level and a **tag** — empty takes the customer's name. The
customer is an agent at once; ending the agency makes it an ordinary
customer again, keeping its wallet and its services.

## What the agent does

- In the bot, the menu has **Agent panel**: its level, its tag, its
  wallet and the last movements of it. The lists show its prices; buying a
  new service asks **which customer it is for** (or *No name*), and the
  services list names each service so.
- In the web app, the buy page has the same name field, the prices are its
  own, and the Wallet page shows its level and its statement.
- An agent pays from its wallet only — nothing is sold on credit; it tops
  up like any customer, or you credit its wallet on the Agents page.
- A discount code is not for an agent's price: the level is its discount.
- Renewals, more traffic and auto-renew of its services are at its price
  too.

## On the panel

The agent's customers are not Shop's: the panel learns nothing about
them. Each account an agent buys carries the agent's **tag** as its
**group** label, so on the panel's users page you can filter, count and
bulk-edit one agent's accounts. (Shop writes the label right after the
account is made; it replaces the plan's group on that account.)

## The statement

An agent's statement (the Agents page, the bot's agent panel, the web
app's Wallet) is read from the wallet's own ledger: every top-up,
purchase, refund, payout, gift and referral reward, with the balance after
each — the last balance is the wallet.

## The API

| Route | What it does |
| --- | --- |
| `GET`/`POST /api/agent-levels`, `PUT`/`DELETE /api/agent-levels/{id}` | levels: `name`, `percent`, `prices` (`productId`, `currency`, `amount`), `referralPercent` |
| `GET /api/agents` | every agent with its level, wallet, services and invited customers |
| `PUT /api/agents/{customerId}` | make a customer an agent, or move it: `levelId`, `tag` |
| `DELETE /api/agents/{customerId}` | end the agency |
| `GET /api/customers/{id}/statement` | any customer's statement (`?currency=`) |

For the customer: `GET /api/c/me` carries `agent`; `GET /api/c/products`
answers its prices; `POST /api/c/orders` takes a `label`; `GET
/api/c/statement` is its own statement.
