# Nexora Shop

[Nexora](https://nexora-panel.org) 的官方扩展，用于销售面板的套餐：商品、订单、钱包、支付和 Telegram 机器人。

> **此版本只是骨架。** 它的安装、在面板中注册、更新和卸载方式与正式的 Shop 完全相同，但目前还不能销售任何东西。商店功能将在后续版本中提供。

[English](../README.md) · [فارسی](fa.md) · [Русский](ru.md) · **中文**

## 安装

在面板中安装（推荐）：**服务 → 扩展 → 浏览**，选择 **Nexora Shop**，回答问题，然后让面板通过 SSH 将其安装到服务器上，或者运行面板给出的命令。健康检查通过后，面板会自动注册 Shop。

手动安装，在 Linux 服务器上以 root 身份运行：

```sh
curl -fsSLO https://raw.githubusercontent.com/Nexora-VPN/shop/main/install.sh
sh install.sh --method script --opt port=8095 --panel-url https://your-panel --claim-code XXXX-XXXX-XXXX-XXXX
```

| 方式 | 运行内容 |
| --- | --- |
| `--method script` | 以 systemd 单元 `nexora-addon-shop` 运行的二进制文件 |
| `--method docker` | [`deploy/compose.yml`](../deploy/compose.yml) 中的 compose 栈（`ghcr.io/nexora-vpn/shop`） |

所有内容都位于 `/opt/nexora-addons/shop`：回答保存在 `.env`，数据保存在 `data/`。

- **更新：** 再次运行 `sh install.sh`（或在面板中点击“在其服务器上更新”）。回答和数据会保留。
- **卸载：** `sh install.sh --uninstall`，加上 `--purge` 会同时删除数据。

| 选项 | 默认值 | |
| --- | --- | --- |
| `port` | `8095` | Shop 监听的端口 |

Shop 免费但不开源——参见[许可证](../LICENSE)。
