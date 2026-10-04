# Payments in Nexora Shop

Languages: **English** · [فارسی](payments.fa.md) · [Русский](payments.ru.md) · [中文](payments.zh.md)

Shop ships **no payment gateway**. It ships the ways to take money that are
not gateways at all — card-to-card, confirmed by a person from the
customer's receipt or by your own bank's SMS — and one general capability: a
**generic HTTP gateway**, a small JSON contract you can point at whatever
intermediary you choose. Which intermediary that is, and whether you may use
it, is your decision and your responsibility.

Every amount is an integer in the currency's smallest unit (tomans for
`IRT`, rials for `IRR`, cents for `USD`) beside the currency's code. Money a
customer pays lands in their **wallet** first and pays their order from
there, so paying a little more leaves the rest in the wallet, and an order
the wallet already covers needs no payment at all.

## Card-to-card

Add your cards in Shop (`POST /api/cards`: the number, the bank, the holder,
the currency). Cards of a currency take turns: each payment is given the
card used longest ago.

Each card-to-card payment asks the customer for a **unique amount**: the
price plus a few units (1, 2, 3 … up to *maxOffset*, 999 by default) that no
other open payment in that currency is asking. The extra units stay in the
customer's wallet. A payment is open for *checkoutMinutes* (60 by default),
but its amount stays held for a day after it opened — whether it expired,
was cancelled, or its receipt was turned down — so a transfer that arrives
late still lands on its own payment and never on another customer's; a
receipt is taken for as long. A customer asking again for the same order or
the same top-up is shown the payment already open, and one customer opens
at most *cardCheckoutsPerDay* card payments a day (10 by default), so
abandoned taps or a script cannot hold every amount near a price.

The payment is confirmed one of two ways.

### By a person, from the receipt

The customer sends the last four digits of the card they paid from, and an
image or PDF of the receipt, or the bank's tracking number. The receipt
waits in **Receipts** in Shop's admin and, if you set up the bot, in a
**forum topic** of your operators' Telegram group, with an approve and a
reject button:

```http
PUT /api/settings/telegram
{"token": "123456:ABC…", "chatId": "-1001234567890", "topicId": 42,
 "approvers": [111111111, 222222222], "language": "fa",
 "apiBase": "https://api.telegram.org"}
```

Only the Telegram users listed in `approvers` can decide a receipt; anyone
else in the group sees it and is told no. A receipt decided anywhere — the
admin, Telegram or the bank's SMS — is marked on its post. Approving the
same receipt twice, or from two places at once, pays once. A tracking number
already used for another payment is refused, and so is the **same receipt
again**: the same file, or the same Telegram photo forwarded — even when the
first one was rejected. A picture that only *looks like* an earlier receipt
(the same one re-saved or re-sent) is let through but marked, in the admin
web and on the Telegram post, with the payment it resembles: a bank's
receipts share a layout, so the comparison is yours.

### By your bank's SMS

Forward your bank's SMS from your phone to Shop and the deposit's amount
confirms the one payment that asked for exactly that amount — no person
needed:

```http
POST https://<shop>/pay/hook/card
X-Nexora-Timestamp: 1790000000
X-Nexora-Signature: <hex HMAC-SHA256 of "1790000000.<body>" under the SMS secret>
Content-Type: application/json

{"from": "+98…", "text": "بانک …\nواریز: 1,500,030 ریال\nمانده: …"}
```

- The **SMS secret** is in `GET /api/settings/payments` (`smsSecret`).
- The body may also be the SMS text itself, or carry `"amount"` when your
  forwarder reads the amount out itself. `"card": <id>` (or `?card=<id>`)
  says which card the SMS is about, when one phone gets SMS for several.
- Shop reads the deposit from the usual shapes — `واریز: 1,500,030`,
  `+1,500,030`, `1,500,030+`, Persian digits — and never from a balance, a
  date, a time or a masked account number. A withdrawal confirms nothing.
- Banks count rials: a card taking `IRT` divides the SMS's amount by 10
  (the card's `smsFactor`; set it to 1 if your bank's SMS counts tomans).
- A signed request is accepted while its timestamp is within five minutes
  of Shop's clock, either way. One signed by the secret outside that is
  answered `401` with "the signature is not within five minutes of Shop's
  clock": sign it again with the current time, check the sender's clock,
  and send it again.
- The same SMS forwarded twice is heard once. While the payment it matched
  is still unbooked — the first time may have failed before it was booked —
  it is taken again, signed anew or the very same request, and books the
  payment once. Once the payment is booked, the very same signed request
  again is refused (`409`: read it as done), and the same SMS signed anew is
  answered `200` as already heard. An SMS whose amount no open payment asks
  for is kept (`GET /api/sms?status=unmatched`) for you to look at, with the
  address it came from and whether it was signed.
- An SMS for the amount of a payment whose receipt was turned down books
  nothing: the receipt goes back to **Receipts** (and the Telegram topic)
  for a person to look at again.
- **A forwarder that cannot sign** may send the secret itself in
  `X-Nexora-Secret` (or `Authorization: Bearer …`) — but only once you turn
  on **Also take SMS that carry the secret** (`smsUnsigned` in the payment
  settings; off on a new install). Anyone who sees such a request can forge
  a deposit, so keep it off unless your forwarder needs it.
- **Make a new secret** (`POST /api/settings/payments/sms-secret`) if one
  leaks: the old one stops at once.
- An address sending twenty refused requests in ten minutes — a wrong or
  missing signature — is answered 429 until it waits. A signature that is
  only outside the five minutes does not count.
- A `503` means Shop could not keep or book the SMS just now: send it
  again, signed again with the current time, and the same SMS books its
  payment once. A `400` is a refusal —
  the body is not an SMS — and sending it again changes nothing.

Signing, in a shell:

```sh
TS=$(date +%s)
BODY='{"text":"واریز: 1,500,030 ریال"}'
SIG=$(printf '%s.%s' "$TS" "$BODY" | openssl dgst -sha256 -hmac "$SMS_SECRET" -hex | sed 's/^.* //')
curl -X POST https://<shop>/pay/hook/card -H "X-Nexora-Timestamp: $TS" -H "X-Nexora-Signature: $SIG" \
  -H 'Content-Type: application/json' --data "$BODY"
```

## The generic HTTP gateway

A gateway in Shop is four addresses on **your** side — usually a small relay
in front of the intermediary you chose — and a shared secret
(`POST /api/gateways`):

```json
{"name": "My gateway", "currencies": "IRT", "enabled": true,
 "createUrl": "https://relay.example/create",
 "verifyUrl": "https://relay.example/verify",
 "refundUrl": "https://relay.example/refund",
 "healthUrl": "https://relay.example/health"}
```

Only `createUrl` is required. Shop makes the secret when you leave it out.
Shop's public address (`PUT /api/settings/payments`, `publicUrl`) must be
set: the gateway sends the customer back there.

**Every request in both directions is signed** the same way: the headers
`X-Nexora-Timestamp` (Unix seconds) and `X-Nexora-Signature`, the hex
HMAC-SHA256 of `<timestamp>.<raw body>` under the gateway's secret. Check
Shop's signature in your relay; Shop refuses a callback whose signature is
wrong or whose timestamp is more than five minutes off Shop's clock.

### create — Shop asks for a payment page

```http
POST <createUrl>
{"checkout": "ck_9f2…", "amount": 150000, "currency": "IRT",
 "description": "order 12", "language": "fa",
 "callbackUrl": "https://<shop>/pay/hook/gateway-1",
 "returnUrl": "https://<shop>/pay/return/ck_9f2…"}
```

Answer `200` with `{"payUrl": "https://…", "reference": "<your id>"}`. Shop
sends the customer to `payUrl`. Send them back to `returnUrl` when they are
done; Shop then asks `verify` and shows what it found. `language` is the
customer's own (`fa`, `en`, `ru` or `zh`).

### callback — you tell Shop

```http
POST <callbackUrl>
{"checkout": "ck_9f2…", "reference": "<your id>", "status": "paid",
 "amount": 150000, "currency": "IRT"}
```

`status` is `paid`, `pending` or `failed` (`success`, `completed`, `ok` read
as paid). When the gateway has a `verifyUrl`, a callback is only a hint:
Shop asks `verify` before it books anything. Repeating a callback is safe —
a checkout is paid once, however often it is reported. The very same signed
callback sent again is taken while its checkout is not yet paid (the first
may have failed before it was booked), and answered `409` once the payment
is booked: read that `409` as done, and stop sending it. A `503` means
Shop could not book it just now (or could not reach your `verifyUrl`):
send it again, signed again with the current time — a signature is taken
within five minutes of Shop's clock, and one outside that is answered `401`
"the signature is not within five minutes of Shop's clock" (check the
sender's clock too; this does not count toward the address's lockout). A
`400` is a refusal — the body is not the contract's, or names a checkout
Shop does not hold — and sending it again changes nothing.

`/pay/hook/gateway-N` is locked out like the SMS address: an address (an
IPv6 address counts as its /64) that sends twenty callbacks in ten minutes
with a wrong or missing signature is answered `429` until it waits — every
callback from it, correctly signed ones too, until fewer than twenty of its
refusals are under ten minutes old. A `429` books nothing: send the
callback again once the wait is over, signed again with the current time.

### verify — Shop asks you

```http
POST <verifyUrl>
{"checkout": "ck_9f2…", "reference": "<your id>", "amount": 150000, "currency": "IRT"}
```

Answer with the same shape as the callback. Shop asks when the customer
comes back, when a callback arrives, every few minutes for a payment whose
callback never came (for three hours), and every quarter of an hour for a
day about a checkout closed on Shop's side — the customer paid another way,
or gave up — so money paid at the gateway all the same still reaches the
customer's wallet. While the gateway is down (below) these timed questions
wait until it is back; they never hold up an order already paid. A gateway
you switch off is still asked about the payments it already took, down or
not.

Money paid in another currency than asked is kept as a payment that waits
for you to confirm it.

### refund and health

```http
POST <refundUrl>
Idempotency-Key: shop-refund-7-3f9a…
{"checkout": "ck_9f2…", "reference": "<your id>", "amount": 50000,
 "currency": "IRT", "idempotencyKey": "shop-refund-7-3f9a…"}
```

Shop takes the amount out of the customer's wallet **before** it asks
(`POST /api/checkouts/{id}/refund`), and names the refund with a key — the
`Idempotency-Key` header and the `idempotencyKey` field carry the same one.
**Your relay makes one refund per key**: a key asked again is answered as
it was the first time — 2xx once that refund was made — and never refunds
a second time. What Shop does with each answer:

- **2xx** — the money is on its way back: the refund is done.
- **A refusal** — a 4xx whose JSON body is `{"refused": true, "reason":
  "…"}`, sent only when nothing was refunded under the key and nothing will
  be: the money goes back to the customer's wallet, and the admin sees the
  reason.
- **Anything else** — a `409` while the key is still being worked on, a
  `429`, any other 4xx, a 5xx, a timeout, an answer Shop cannot read — says
  nothing for certain: the refund stays on its way, out of the wallet, and
  the admin asks for it again, which sends the same key. Nothing goes back
  to the wallet until you answer 2xx or refuse.
- **A 2xx for a key you refused** is not ignored: the money went back to the
  wallet and out through you as well, and Shop lists it under **Backup →
  After a panel restore** for the admin to settle.

Without a refund address, pay a customer back by hand
(`POST /api/customers/{id}/payout`). `health` is a `GET` that answers 2xx
while the gateway can take money.

**A gateway that stops answering** is hidden from customers: Shop asks its
health address every minute, and a payment it would not open counts the
same. After three failures in a row it is down — customers are offered the
other ways to pay, card-to-card among them, and the admins' Telegram group
is told once; the admin web's dashboard says so too. The first good answer
brings it back, and the group is told that as well. A gateway without a
health address is tried again fifteen minutes after it went down, and its
next payment decides.

## Exchange rates

A **rate** says how many of one currency one of another is — tomans per
dollar, say (`PUT /api/settings/rates`, or **Payment methods → Exchange
rates**). Its source is any JSON address you choose — Shop names none — with
the **path** to the number in its answer (`data.price`, `result.0.last`; a
string with thousands separators is read too) and a **multiplier** (0.1 for
a source in rials). It is asked every ten minutes. A **manual rate** is
used when the source has not answered for its **age** (60 minutes by
default) or when you choose it over the source; with neither, there is no
rate.

A rate does two things:

- **A product priced only in another currency** — dollars, say — is sold in
  the shop's currency at the day's rate, rounded up to **round to** (1,000
  tomans, say). The ledger never sees the dollar.
- **A gateway that takes only another currency** — USDT, say — is offered
  for the shop's currency too: the checkout asks the converted amount,
  rounded up, and credits the wallet with the amount due, the rate locked
  when the payment opened. The ledger records the conversion through its
  `exchange` account. Such a payment is refunded by hand, out of the
  wallet.
