# The web app: portal and mini-app

Languages: **English** · [فارسی](portal.fa.md) · [Русский](portal.ru.md) · [中文](portal.zh.md)

Shop's customers have one web app, at `https://<shop>/app/`, which is two
things at once:

- **The portal**, in any browser. It keeps your shop selling when Telegram
  is blocked or your bot is lost: a customer signs in with a code sent to
  their **email** or **mobile number**, or one the **bot** confirms, and
  buys, pays, renews and reads their services and usage as in the bot. It
  installs on a phone's home screen (a PWA).
- **The mini-app**, inside Telegram. The bot's menu shows **Open the shop**
  once Shop's public address is `https://`; Telegram signs the customer in
  by itself. A customer who bought on the web links their email or number
  once (a code proves it) and sees the same services, wallet and orders.

Put Shop on an address of its own — never beside the panel's — behind
HTTPS, and set it as the public address (`PUT /api/settings/payments`,
`publicUrl`). Telegram opens mini-apps only over HTTPS.

## Setting it up

The install asks for Shop's **public address**, whether Shop should get its
**HTTPS certificate** itself (`https: acme`), and the **bot's token** — all
three optional, all changeable later. Then Shop's admin shows a checklist
until Shop can sell: the address, checked from outside; the bot, checked
with Telegram and its menu button set to the mini-app; **your Telegram as
an admin** — open the link or scan the QR code and press Start; **the
receipts group** — add the bot to your admins' group and send `/receipts`
in the topic you want; cards; products picked from the panel's plans.
Nothing asks for an id.

With `https: acme`, the domain of the public address must point at Shop's
server and port 443 must be free there: Shop answers the certificate
authority's check on 443 itself (TLS-ALPN-01), so nothing listens on 80,
and renews the certificate on its own. Shop's own port (8095) stays plain
HTTP for the panel.

With `https: self-signed` — an address by IP, such as
`https://203.0.113.9:8443`, with no domain a CA would sign — Shop makes a
certificate of its own and answers on the port the address names. Browsers
warn once; the traffic is encrypted, and **Set-up** shows the
certificate's fingerprint to compare with the browser's. Telegram opens no
mini-app on such an address, so the bot offers none: customers use the bot
and the web app in a browser.

## Sign-in by email

Your SMTP server (`PUT /api/settings/email`):

```json
{"host": "smtp.example.com", "port": 587, "username": "shop@example.com",
 "password": "…", "from": "shop@example.com", "security": "starttls"}
```

`security` is `starttls` (port 587), `tls` (port 465) or `none` (only for a
relay on the same host). A code is six digits, good for ten minutes and
five tries; an address gets three codes in fifteen minutes, an IP ten an
hour.

## Sign-in by SMS: the generic contract

Shop names no SMS service. Point it at yours through a small relay
(`PUT /api/settings/sms`, `{"url": "https://relay.example/sms"}` — Shop
makes the secret when you leave it out):

```http
POST <url>
X-Nexora-Timestamp: 1790000000
X-Nexora-Signature: <hex HMAC-SHA256 of "1790000000.<body>" under the secret>
Content-Type: application/json

{"to": "+989121234567", "text": "Your shop sign-in code: 123456"}
```

Answer 2xx once the message is on its way. The signature is the same as on
every call Shop makes to a service of yours (see [payments](payments.md));
check it in the relay. Numbers arrive in international form; Iranian
numbers typed as `0912…` become `+98912…`.

## Sign-in by the bot

When a bot is set, the portal offers **Sign in with the Telegram bot**: it
opens `t.me/<bot>?start=login_<code>`, the customer presses Start, and the
page signs in by itself once they confirm. The bot first asks — "a
browser asks to sign in to your account as …", with the browser's address,
device and time — and signs in only on **Confirm**; **Refuse** spends the
code. The code is good for five minutes, and only the browser that asked
for it is signed in: someone who sends a customer their own link gets
nothing. It needs Telegram to be reachable — the email and SMS sign-ins
are for when it is not.

Codes, sign-ins and payment checks are limited per client address. Behind
a reverse proxy that terminates TLS, set `NEXORA_OPT_TRUSTED_PROXIES` in
the install's `.env` to the proxy's addresses or ranges
(`127.0.0.1, 10.0.0.0/8`): Shop then reads the client from the proxy's
`X-Forwarded-For`. Left empty, the default, no forwarded header is
believed.

## What a customer can do

My services (the link with a copy button and a QR code, usage, the date,
renew, more traffic, the wallet-paid automatic renewal), buy, pay — by card
with the receipt's photo, PDF or tracking number, or through your gateway
— the wallet and its top-up, the free trial, discount and gift codes and
their referral link ([Discount codes, gift codes and
referrals](promotions.md)). It speaks the languages the shop turned on,
each customer in their own, with a switch at the top; and it says so when
new services are paused, or when an order went back to the wallet because
the panel had no room.
