# Nexora Shop

[Nexora](https://nexora-panel.org) 的官方扩展，用于销售面板的套餐：商品、订单、钱包、卡对卡转账和网关支付、Telegram 机器人、网页应用、折扣码和礼品码、推荐和代理。

语言：[English](../README.md) · [فارسی](fa.md) · [Русский](ru.md) · **中文**

## 安装

在面板中安装（推荐）：**服务 → 扩展 → 浏览**，选择 **Nexora Shop** 并回答问题，然后让面板通过 SSH 把它装到一台服务器上，或者自己运行面板给出的命令。健康检查有响应后，面板会自动注册 Shop。

手动安装：在 Linux 服务器上以 root 身份运行：

```sh
curl -fsSLO https://raw.githubusercontent.com/Nexora-VPN/shop/main/install.sh
sh install.sh --method script --opt port=8095 --panel-url https://your-panel --claim-code XXXX-XXXX-XXXX-XXXX
```

| 方式 | 运行内容 |
| --- | --- |
| `--method script` | 以 systemd 单元 `nexora-addon-shop` 运行的二进制文件 |
| `--method docker` | [`deploy/compose.yml`](../deploy/compose.yml) 中的 compose 栈（`ghcr.io/nexora-vpn/shop`） |

所有内容都在 `/opt/nexora-addons/shop` 下：回答保存在 `.env`，数据保存在 `data/`。

- **更新：** 再次运行 `sh install.sh`（或在面板中点击 **在其服务器上更新**）。回答和数据都会保留。
- **卸载：** `sh install.sh --uninstall`，加上 `--purge` 会同时删除数据。

| 选项 | 默认值 | |
| --- | --- | --- |
| `port` | `8095` | Shop 监听的端口 |
| `database` | `sqlite` | `sqlite` 把所有数据保存在 `data/`；`postgres` 使用您自己运行的服务器 |
| `database_dsn` | | PostgreSQL 连接串（仅在选择 `postgres` 时询问） |
| `admin_username` | `admin` | Shop 自己的管理员账户 |
| `admin_password` | | 该账户的密码，至少 10 个字符；仅在创建账户时使用一次——之后请在 Shop 中修改 |
| `base_path` | 随机 | Shop 管理后台、其 API 和面板请求所在的路径；客户页面（`/app/`、`/pay/`）保留在根路径，永远不会显示它。面板和 `install.sh` 会随机生成一个；`base_path=`（留空）把管理后台放在根路径。更新时保留安装已有的值 |
| `https` | `off` | `acme`：为公开地址的域名获取证书，在 443 上；`self-signed`：Shop 自己的证书，用于以 IP 访问的地址（浏览器会警告，Telegram 小程序无法打开）；`off`：不用证书，或用您自己的代理 |

然后在 Shop 的地址及其基础路径上打开管理后台——`install.sh` 会打印该地址，面板也可从扩展所在行打开——按 **快速设置** 完成：机器人、公开地址、一种支付方式和第一个商品。

## 指南

| 指南 | 内容 |
| --- | --- |
| [管理后台](admin.zh.md) | 每个页面、机器人文案、报表 |
| [支付](payments.zh.md) | 凭证和银行短信确认的卡对卡转账、通用网关、汇率 |
| [网页应用](portal.zh.md) | 网页门户和 Telegram 小程序，通过邮件、短信或机器人登录 |
| [优惠码和推荐](promotions.zh.md) | 折扣码、礼品码、推荐奖励 |
| [代理](agents.zh.md) | 等级、预付费代理、代理账单 |
| [备份与恢复](backup.zh.md) | Shop 自己的加密备份、迁移到新服务器、面板恢复之后 |

## 客户语言

Shop 支持波斯语、英语、俄语和中文。在 **设置** 中开启客户使用的语言。如果客户自己的语言（其 Telegram 的语言，或在机器人或网页应用中选择的语言）已开启，就用该语言服务，否则用英语，或第一个开启的语言。商品表单会为每种已开启的语言询问名称；留空的名称会显示另一种语言的名称。关闭某种语言后，其客户会转到最接近的已开启语言。机器人的文案可以按语言改写（**机器人文案**）。

## 提醒，或通知扩展

默认情况下，Shop 会就客户的账户通知客户：自己在到期前发出的提醒，以及面板的警告——即将到期、已到期、流量已用部分或用完、在面板上续费或删除。如果您运行了[通知扩展](https://github.com/Nexora-VPN/notif)（它为面板上的每个账户做同样的事），请在 **设置** 中关闭 **由商店通知客户到期、流量、续订和删除**，以免客户收到两次。Shop 自己做的事——购买、凭证、钱包、钱包余额不足而未能完成的自动续费——仍由 Shop 通知。

## 面板没有余量时

Shop 不检查自己的许可证，由面板来检查。当面板因许可证已满而拒绝创建新账户时，Shop 会如实处理：订单款项立即退回客户钱包，客户会被告知原因，管理员的 Telegram 话题会收到面板的原话，新服务和试用暂停一小时，以免后来的客户再遇到同样的拒绝。续费和加流量照常进行。升级面板许可证或腾出余量后，在概览页点击 **重新开放销售**。

## 文件

| 文件 | 说明 |
| --- | --- |
| [`nexora-addon.json`](../nexora-addon.json) | 由 Nexora 签名的清单；扩展目录和面板从这里读取 |
| [`install.sh`](../install.sh) | 在 Linux 服务器上安装、更新或卸载 |
| [`deploy/compose.yml`](../deploy/compose.yml) | docker 方式运行的栈 |

每个发布版本附带 `linux-amd64` 和 `linux-arm64` 的二进制文件及其 `SHA256SUMS`，以及 Nexora 对其的签名 `SHA256SUMS.sig`：只有当 `install.sh` 和二进制文件与之相符时，面板才会通过 SSH 安装 Shop。Shop 免费但不开源——参见[许可证](../LICENSE)。
