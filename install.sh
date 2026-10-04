#!/bin/sh
# Installs, updates or removes Nexora Shop on a Linux host — by hand, or
# by the panel over SSH (the same way it installs a node). Run it as root.
#
#   sh install.sh --method docker --opt port=8095 --panel-url https://panel.example --claim-code ABC123
#   sh install.sh --method script --version v0.1.0 --opt base_path=k3x9q2
#   sh install.sh --uninstall [--purge]
#
# --method script   the binary under a systemd unit (no Docker needed)
# --method docker   the compose stack in deploy/compose.yml
# --version TAG     a release tag (default: the latest release)
# --binary-file F   install this archive instead of downloading one (script)
# --sha256 HEX      the archive's SHA-256, checked before it is installed: the
#                   panel hands it from the release's signed SHA256SUMS
# --opt KEY=VALUE   an answer to one of the manifest's install options; repeat.
#                   A first install with no base_path draws one (the admin's
#                   path); base_path= puts the admin at the root.
# --panel-url URL   the panel's address, passed as NEXORA_PANEL_URL
# --claim-code C    the one-time code the panel registers the addon with
# --uninstall       stop and remove the addon; --purge also deletes its data
#
# Running it again updates in place: the answers already given are kept
# unless --opt changes them, and the data directory is never touched.
set -eu

SLUG="shop"
REPO="Nexora-VPN/shop"
BIN="nexora-shop"
DIR="/opt/nexora-addons/${SLUG}"
UNIT="nexora-addon-${SLUG}"

METHOD=""
VERSION=""
BINARY_FILE=""
SHA256=""
PANEL_URL=""
CLAIM_CODE=""
UNINSTALL=0
PURGE=0
OPTS=""

die() { echo "install: $*" >&2; exit 1; }

while [ $# -gt 0 ]; do
	case "$1" in
	--method) METHOD="$2"; shift 2 ;;
	--version) VERSION="$2"; shift 2 ;;
	--binary-file) BINARY_FILE="$2"; shift 2 ;;
	--sha256) SHA256="$2"; shift 2 ;;
	--opt)
		case "$2" in *=*) ;; *) die "--opt takes KEY=VALUE" ;; esac
		OPTS="${OPTS}$2
"
		shift 2 ;;
	--panel-url) PANEL_URL="$2"; shift 2 ;;
	--claim-code) CLAIM_CODE="$2"; shift 2 ;;
	--uninstall) UNINSTALL=1; shift ;;
	--purge) PURGE=1; shift ;;
	*) die "unknown argument $1" ;;
	esac
done

[ "$(id -u)" = 0 ] || die "run as root"

if [ "$UNINSTALL" = 1 ]; then
	if [ -f "/etc/systemd/system/${UNIT}.service" ]; then
		systemctl disable --now "$UNIT" 2>/dev/null || true
		rm -f "/etc/systemd/system/${UNIT}.service"
		systemctl daemon-reload
	fi
	if [ -f "${DIR}/compose.yml" ] && command -v docker >/dev/null 2>&1; then
		docker compose -f "${DIR}/compose.yml" --env-file "${DIR}/.env" down || true
	fi
	if [ "$PURGE" = 1 ]; then
		rm -rf "$DIR"
	else
		rm -rf "${DIR}/bin" "${DIR}/compose.yml"
	fi
	echo "removed ${SLUG}"
	exit 0
fi

# An update keeps the method the addon was installed with.
if [ -z "$METHOD" ] && [ -f "${DIR}/.method" ]; then
	METHOD="$(cat "${DIR}/.method")"
fi
case "$METHOD" in
script | docker) ;;
*) die "--method script or --method docker" ;;
esac

if [ -z "$VERSION" ]; then
	VERSION="$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -n 1)"
	[ -n "$VERSION" ] || die "could not read the latest release of ${REPO}"
fi

# A first install, not an update: no answers written yet.
FRESH=1
[ ! -f "${DIR}/.env" ] || FRESH=0

mkdir -p "${DIR}/data"
chmod 700 "${DIR}"
echo "$METHOD" >"${DIR}/.method"

# envquote VALUE: the value as both readers of the .env take it literally —
# systemd's EnvironmentFile and docker compose's env_file. Single quotes are
# literal to both; a value holding one goes in double quotes, with \ and "
# escaped, and for compose, which expands $ inside them, $ doubled.
envquote() {
	case "$1" in
	*\'*) ;;
	*)
		printf "'%s'" "$1"
		return
		;;
	esac
	v="$(printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')"
	[ "$METHOD" != docker ] || v="$(printf '%s' "$v" | sed 's/\$/$$/g')"
	printf '"%s"' "$v"
}

# setenv KEY VALUE: replace or add one line of the .env file.
setenv() {
	touch "${DIR}/.env"
	chmod 600 "${DIR}/.env"
	grep -v "^$1=" "${DIR}/.env" >"${DIR}/.env.tmp" || true
	printf '%s=%s\n' "$1" "$(envquote "$2")" >>"${DIR}/.env.tmp"
	mv "${DIR}/.env.tmp" "${DIR}/.env"
	chmod 600 "${DIR}/.env" # the mv carries the temporary file's mode, not the 600 above
}

printf '%s' "$OPTS" | while IFS= read -r kv; do
	[ -n "$kv" ] || continue
	key="$(printf '%s' "${kv%%=*}" | tr 'a-z' 'A-Z')"
	setenv "NEXORA_OPT_${key}" "${kv#*=}"
done
[ -z "$PANEL_URL" ] || setenv NEXORA_PANEL_URL "$PANEL_URL"
[ -z "$CLAIM_CODE" ] || setenv NEXORA_CLAIM_CODE "$CLAIM_CODE"
setenv NEXORA_ADDON_VERSION "${VERSION#v}"

# getenv KEY: a value of the .env, its quotes taken off (setenv's quoting
# of a value with no quote in it).
getenv() {
	sed -n "s/^$1=//p" "${DIR}/.env" 2>/dev/null | tail -n 1 | sed -e "s/^'\(.*\)'\$/\1/" -e 's/^"\(.*\)"$/\1/'
}

# The admin's base path: a first install the command gives none draws
# one, so the admin is not where a scanner looks; an update keeps what
# the install has — none, for one from before base paths, is the root.
if [ "$FRESH" = 1 ] && ! grep -q '^NEXORA_OPT_BASE_PATH=' "${DIR}/.env"; then
	setenv NEXORA_OPT_BASE_PATH "$(LC_ALL=C tr -dc 'a-z0-9' </dev/urandom | head -c 12)"
fi

# Shop's own HTTPS answers on the public address's port: 443 for acme,
# whatever the CA's check needs, and for self-signed the port the address
# names (443 when it names none). Compose publishes it only then, so a
# host whose 443 is taken (a node, a proxy) starts Shop without.
HTTPS_MODE="$(getenv NEXORA_OPT_HTTPS)"
HTTPS_PORT=443
if [ "$HTTPS_MODE" = self-signed ]; then
	p="$(getenv NEXORA_OPT_PUBLIC_URL | sed -n 's#^https://[^/]*:\([0-9][0-9]*\)\(/.*\)\{0,1\}$#\1#p')"
	[ -z "$p" ] || HTTPS_PORT="$p"
	[ "$HTTPS_PORT" != "$(getenv NEXORA_OPT_PORT)" ] || die "the public address's port ${HTTPS_PORT} is Shop's own port; give the public address another"
fi
case "$HTTPS_MODE" in
acme | self-signed)
	setenv NEXORA_HTTPS_PUBLISH "${HTTPS_PORT}:8443"
	[ "$METHOD" != script ] || setenv NEXORA_HTTPS_LISTEN ":${HTTPS_PORT}"
	;;
*) setenv NEXORA_HTTPS_PUBLISH "127.0.0.1::8443" ;;
esac

case "$METHOD" in
script)
	case "$(uname -m)" in
	x86_64 | amd64) ARCH=amd64 ;;
	aarch64 | arm64) ARCH=arm64 ;;
	*) die "no build of ${SLUG} for $(uname -m)" ;;
	esac
	setenv NEXORA_DATA_DIR "${DIR}/data"
	tmp="$(mktemp -d)"
	trap 'rm -rf "$tmp"' EXIT
	if [ -n "$BINARY_FILE" ]; then
		cp "$BINARY_FILE" "${tmp}/addon.tar.gz"
	else
		curl -fsSL -o "${tmp}/addon.tar.gz" \
			"https://github.com/${REPO}/releases/download/${VERSION}/${BIN}-linux-${ARCH}.tar.gz"
	fi
	if [ -n "$SHA256" ]; then
		if command -v sha256sum >/dev/null 2>&1; then
			got="$(sha256sum "${tmp}/addon.tar.gz" | cut -d' ' -f1)"
		else
			got="$(shasum -a 256 "${tmp}/addon.tar.gz" | cut -d' ' -f1)"
		fi
		[ "$got" = "$(printf '%s' "$SHA256" | tr 'A-F' 'a-f')" ] || die "the archive's SHA-256 is ${got}, not the ${SHA256} the release signed"
	fi
	tar -xzf "${tmp}/addon.tar.gz" -C "$tmp"
	mkdir -p "${DIR}/bin"
	install -m 755 "${tmp}/${BIN}" "${DIR}/bin/${BIN}"
	cat >"/etc/systemd/system/${UNIT}.service" <<UNIT
[Unit]
Description=Nexora addon ${SLUG}
After=network-online.target
Wants=network-online.target

[Service]
EnvironmentFile=${DIR}/.env
WorkingDirectory=${DIR}
ExecStart=${DIR}/bin/${BIN}
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
UNIT
	systemctl daemon-reload
	systemctl enable "$UNIT" >/dev/null 2>&1
	systemctl restart "$UNIT"
	;;
docker)
	command -v docker >/dev/null 2>&1 || die "docker is not installed; use --method script"
	chown 10001 "${DIR}/data" # the image runs as uid 10001
	curl -fsSL -o "${DIR}/compose.yml" "https://raw.githubusercontent.com/${REPO}/${VERSION}/deploy/compose.yml"
	docker compose -f "${DIR}/compose.yml" --env-file "${DIR}/.env" pull
	docker compose -f "${DIR}/compose.yml" --env-file "${DIR}/.env" up -d
	;;
esac

echo "installed ${SLUG} ${VERSION} (${METHOD}) in ${DIR}"
BASE="$(getenv NEXORA_OPT_BASE_PATH | tr -d /)"
PORT="$(getenv NEXORA_OPT_PORT)"
echo "the admin: http://<this host>:${PORT:-8095}/${BASE}${BASE:+/ — keep the path to yourself}"
