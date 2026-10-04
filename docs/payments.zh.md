# Nexora Shop 的支付

语言：[English](payments.md) · [فارسی](payments.fa.md) · [Русский](payments.ru.md) · **中文**

Shop **不自带任何支付网关**。它自带的是那些根本不算网关的收款方式——卡对卡转账，由人根据客户的凭证确认，或由您自己银行的短信确认——以及一项通用能力：**通用 HTTP 网关**，一个小型 JSON 协议，您可以把它接到自己选择的任何支付中介上。选用哪个中介、是否可以使用它，由您决定，也由您负责。

每个金额都是该货币最小单位下的整数（`IRT` 为托曼，`IRR` 为里亚尔，`USD` 为美分），并附带货币代码。客户付的钱先进入其**钱包**，再从钱包支付订单，所以多付的部分留在钱包里，而钱包余额已够支付的订单根本不需要再付款。

## 卡对卡转账

在 Shop 中添加您的银行卡（`POST /api/cards`：卡号、银行、持卡人、货币）。同一货币的银行卡轮流使用：每笔付款分配给最久未使用的那张卡。

每笔卡对卡付款都会要求客户支付一个**唯一金额**：价格加上几个单位（1、2、3……最多 *maxOffset*，默认 999），且该货币下没有其他未完成的付款要求同样的金额。多出的单位留在客户钱包里。付款开启 *checkoutMinutes*（默认 60 分钟），但其金额在开启后保留一天——无论已过期、已取消还是凭证被拒绝——使迟到的转账仍落在它自己的付款上，绝不会落到其他客户的付款上；凭证在同一期限内仍被接受。客户再次为同一订单或同一充值请求付款时，会看到已开启的那笔付款；每位客户每天最多开启 *cardCheckoutsPerDay* 笔卡对卡付款（默认 10），使放弃的点击或脚本无法占满某个价格附近的所有金额。

付款通过以下两种方式之一确认。

### 由人根据凭证确认

客户发送付款卡号的后四位，以及凭证的图片或 PDF，或银行的交易流水号。凭证会在 Shop 管理后台的 **转账凭证** 中等待审核；如果设置了机器人，还会出现在操作员 Telegram 群组的一个**论坛话题**中，带有批准和拒绝按钮：

```http
PUT /api/settings/telegram
{"token": "123456:ABC…", "chatId": "-1001234567890", "topicId": 42,
 "approvers": [111111111, 222222222], "language": "fa",
 "apiBase": "https://api.telegram.org"}
```

只有 `approvers` 中列出的 Telegram 用户可以处理凭证；群组中的其他人能看到，但操作会被拒绝。无论在哪里处理的凭证——管理后台、Telegram 还是银行短信——都会在其帖子上标明。同一凭证批准两次，或在两处同时批准，只会付款一次。已用于其他付款的流水号会被拒绝，**同一凭证再次提交**也会被拒绝：同一个文件，或转发的同一张 Telegram 照片——即使第一次被拒绝过。只是*看起来像*以前凭证的图片（同一张重新保存或重新发送）会放行，但在管理后台和 Telegram 帖子上标出与之相似的付款：同一家银行的凭证版式相同，所以由您来比对。

### 由银行短信确认

把银行短信从手机转发给 Shop，入账金额会确认恰好要求该金额的那一笔付款——无需人工：

```http
POST https://<shop>/pay/hook/card
X-Nexora-Timestamp: 1790000000
X-Nexora-Signature: <hex HMAC-SHA256 of "1790000000.<body>" under the SMS secret>
Content-Type: application/json

{"from": "+98…", "text": "بانک …\nواریز: 1,500,030 ریال\nمانده: …"}
```

- **短信密钥** 在 `GET /api/settings/payments` 中（`smsSecret`）。
- 请求体也可以直接是短信文本，或者在转发器自己读出金额时携带 `"amount"`。当一部手机接收多张卡的短信时，用 `"card": <id>`（或 `?card=<id>`）指明短信对应哪张卡。
- Shop 能从常见格式中读出入账金额——`واریز: 1,500,030`、`+1,500,030`、`1,500,030+`、波斯语数字——绝不会从余额、日期、时间或掩码账号中读取。支出短信不会确认任何付款。
- 银行以里亚尔计数：收 `IRT` 的卡会把短信中的金额除以 10（即该卡的 `smsFactor`；如果您的银行短信以托曼计数，请设为 1）。
- 签名请求的时间戳与 Shop 的时钟相差不超过五分钟（无论早晚）时才有效。由密钥签名但超出该范围的请求会收到 `401`“the signature is not within five minutes of Shop's clock”（签名不在 Shop 时钟的五分钟以内）：请用当前时间重新签名，检查发送方的时钟，然后再发送。
- 同一条短信转发两次只计一次。在它匹配的付款尚未入账时（第一次可能在入账前失败了），它会被再次接受——无论是重新签名还是完全相同的请求——并只为该付款入账一次。付款入账之后，完全相同的签名请求再次发送会被拒绝（`409`：请视为已完成），而重新签名的同一条短信会收到 `200`“已收到过”。没有任何未完成付款要求其金额的短信会被保留（`GET /api/sms?status=unmatched`）供您查看，并附有来源地址和是否签名。
- 金额对应某笔凭证已被拒绝的付款的短信不会记账：该凭证会回到 **凭证**（以及 Telegram 话题）中，由人再次查看。
- **无法签名的转发器** 可以在 `X-Nexora-Secret`（或 `Authorization: Bearer …`）中直接发送密钥——但仅在您开启 **也接受携带密钥而非签名的短信** 之后（支付设置中的 `smsUnsigned`；新安装时关闭）。任何看到此类请求的人都能伪造入账，所以除非转发器需要，请保持关闭。
- 密钥泄露时请 **生成新密钥**（`POST /api/settings/payments/sms-secret`）：旧密钥立即失效。
- 某个地址若在十分钟内有二十次请求被拒绝（签名错误或缺失），在它停下来等待之前会一直收到 429。仅仅是超出五分钟的签名不计入。
- `503` 表示 Shop 此刻未能保存或入账这条短信：请用当前时间重新签名后再次发送，同一条短信只会为其付款入账一次。`400` 表示拒绝（请求体不是短信），再次发送也不会有任何改变。

在 shell 中签名：

```sh
TS=$(date +%s)
BODY='{"text":"واریز: 1,500,030 ریال"}'
SIG=$(printf '%s.%s' "$TS" "$BODY" | openssl dgst -sha256 -hmac "$SMS_SECRET" -hex | sed 's/^.* //')
curl -X POST https://<shop>/pay/hook/card -H "X-Nexora-Timestamp: $TS" -H "X-Nexora-Signature: $SIG" \
  -H 'Content-Type: application/json' --data "$BODY"
```

## 通用 HTTP 网关

Shop 中的网关就是**您这一侧**的四个地址——通常是放在您所选中介前面的一个小型中继——加上一个共享密钥（`POST /api/gateways`）：

```json
{"name": "My gateway", "currencies": "IRT", "enabled": true,
 "createUrl": "https://relay.example/create",
 "verifyUrl": "https://relay.example/verify",
 "refundUrl": "https://relay.example/refund",
 "healthUrl": "https://relay.example/health"}
```

只有 `createUrl` 是必填的。不填密钥时由 Shop 生成。必须设置 Shop 的公开地址（`PUT /api/settings/payments`，`publicUrl`）：网关会把客户送回那里。

**双向的每个请求都以同样方式签名**：请求头 `X-Nexora-Timestamp`（Unix 秒）和 `X-Nexora-Signature`，即用网关密钥对 `<timestamp>.<raw body>` 计算的十六进制 HMAC-SHA256。请在中继中校验 Shop 的签名；签名错误或时间戳与 Shop 时钟相差超过五分钟的回调会被 Shop 拒绝。

### create——Shop 请求支付页面

```http
POST <createUrl>
{"checkout": "ck_9f2…", "amount": 150000, "currency": "IRT",
 "description": "order 12", "language": "fa",
 "callbackUrl": "https://<shop>/pay/hook/gateway-1",
 "returnUrl": "https://<shop>/pay/return/ck_9f2…"}
```

返回 `200` 和 `{"payUrl": "https://…", "reference": "<your id>"}`。Shop 会把客户送到 `payUrl`。客户完成后，把他们送回 `returnUrl`；Shop 随后调用 `verify` 并显示结果。`language` 是客户自己的语言（`fa`、`en`、`ru` 或 `zh`）。

### callback——您通知 Shop

```http
POST <callbackUrl>
{"checkout": "ck_9f2…", "reference": "<your id>", "status": "paid",
 "amount": 150000, "currency": "IRT"}
```

`status` 为 `paid`、`pending` 或 `failed`（`success`、`completed`、`ok` 视为已付款）。网关设有 `verifyUrl` 时，回调只是一个提示：Shop 会先调用 `verify` 再记账。重复回调是安全的——无论报告多少次，一笔 checkout 只付款一次。完全相同的签名回调再次发送时，只要付款尚未入账就会被接受（第一次可能在入账前失败了），入账之后则返回 `409`：请把这个 `409` 视为已完成，不要再发送。`503` 表示 Shop 此刻未能入账（或无法访问您的 `verifyUrl`）：请用当前时间重新签名后再次发送——签名在与 Shop 时钟相差五分钟以内时有效，超出的签名会收到 `401`“the signature is not within five minutes of Shop's clock”（也请检查发送方的时钟；此应答不计入该地址的封锁次数）。`400` 表示拒绝（请求体不符合约定，或指向 Shop 不存在的付款），再次发送也不会有任何改变。

`/pay/hook/gateway-N` 与短信地址一样会被封锁：某个地址（IPv6 地址按其 /64 计）若在十分钟内发送二十次签名错误或缺失的回调，在它停下来等待之前会一直收到 `429`——它发来的所有回调都是如此，包括签名正确的回调——直到其最近十分钟内的被拒次数少于二十次。`429` 不会记账：等待结束后，请用当前时间重新签名并再次发送该回调。

### verify——Shop 询问您

```http
POST <verifyUrl>
{"checkout": "ck_9f2…", "reference": "<your id>", "amount": 150000, "currency": "IRT"}
```

按与回调相同的格式应答。Shop 会在客户返回时、收到回调时，对一直没有回调的付款每隔几分钟（持续三小时）进行查询，并对在 Shop 一侧已关闭的付款（客户改用其他方式付款或放弃）在一天内每十五分钟查询一次，使仍在网关付了的钱也能进入客户钱包。网关不可用期间（见下文），这些定时查询会等到它恢复；它们绝不会耽搁已付款的订单。被您停用的网关，无论是否不可用，仍会被查询它已收取的付款。

以非要求货币支付的款项会保留为一笔付款，等待您确认。

### refund 和 health

```http
POST <refundUrl>
Idempotency-Key: shop-refund-7-3f9a…
{"checkout": "ck_9f2…", "reference": "<your id>", "amount": 50000,
 "currency": "IRT", "idempotencyKey": "shop-refund-7-3f9a…"}
```

Shop 在询问**之前**就从客户钱包中扣除该金额（`POST /api/checkouts/{id}/refund`），并用一个键为这笔退款命名——`Idempotency-Key` 请求头和 `idempotencyKey` 字段携带同一个键。**您的中转对每个键只退款一次**：同一个键再次请求时，按第一次的结果应答——退款已完成则返回 2xx——绝不再退第二次。Shop 对每种应答的处理：

- **2xx**——款项正在退回：退款完成。
- **拒绝**——一个 4xx，其 JSON 正文为 `{"refused": true, "reason": "…"}`，仅在该键下没有也不会有任何退款时发送：款项回到客户钱包，管理员可看到原因。
- **其他任何应答**——键仍在处理中时的 `409`、`429`、其他任何 4xx、5xx、超时、Shop 无法读取的应答——都不能确定结果：退款保持“在途”，不在钱包中，管理员再次请求时会发送同一个键。在您返回 2xx 或拒绝之前，钱包里不会退回任何东西。
- **对您已拒绝的键返回 2xx** 不会被忽略：这笔钱既回到了钱包，又经您退出；Shop 会把它列在 **备份 → 面板恢复之后** 中，由管理员处理。

没有退款地址时，请手动退款给客户（`POST /api/customers/{id}/payout`）。`health` 是一个 `GET` 请求，网关能收款时返回 2xx。

**停止响应的网关** 会对客户隐藏：Shop 每分钟请求一次其健康检查地址，无法开启的付款也计为一次失败。连续失败三次即视为宕机——客户会看到其他付款方式，包括卡对卡转账，管理员的 Telegram 群组会收到一次通知；管理后台的概览页也会显示。第一次正常响应即恢复，群组同样会收到通知。没有健康检查地址的网关在宕机十五分钟后会再次尝试，由其下一笔付款决定状态。

## 汇率

**汇率** 表示一种货币等于多少另一种货币——比如每美元多少托曼（`PUT /api/settings/rates`，或 **支付方式 → 汇率**）。其来源是您选择的任意 JSON 地址——Shop 不指定任何来源——并设置应答中数值的**数值路径**（`data.price`、`result.0.last`；带千位分隔符的字符串也能读取）和**乘以**的系数（来源以里亚尔计时为 0.1）。每十分钟查询一次。当来源超过**来源汇率有效期**（默认 60 分钟）没有应答，或您选择使用手动汇率时，使用**手动汇率**；两者都没有时，就没有汇率。

汇率有两个作用：

- **只以另一种货币定价的商品**——比如美元——按当日汇率以商店货币出售，向上取整到**换算价格取整到**所设的单位（比如 1,000 托曼）。账本中永远不会出现美元。
- **只收另一种货币的网关**——比如 USDT——也可用于商店货币：checkout 要求支付换算后的金额（向上取整），并把应付金额存入钱包，汇率在付款开启时锁定。账本通过其 `exchange` 账户记录换算。此类付款需从钱包中手动退款。
