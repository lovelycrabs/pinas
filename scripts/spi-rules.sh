#!/bin/bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as root: sudo bash $0" >&2
    exit 1
fi

RULES_FILE="/etc/udev/rules.d/99-spidev.rules"
BIND_SCRIPT="/usr/local/sbin/pinas-spidev-bind"
SPI_GROUP="spi"

if ! getent group "${SPI_GROUP}" >/dev/null; then
    groupadd --system "${SPI_GROUP}"
fi

install -d -m 0755 /usr/local/sbin /etc/udev/rules.d

cat > "${BIND_SCRIPT}" <<'EOF'
#!/bin/bash
set -euo pipefail

SPI_NAME="${1:?SPI device name is required}"
SPI_DEVICE="/sys/bus/spi/devices/${SPI_NAME}"
SPI_DRIVER="/sys/bus/spi/drivers/spidev"

[ -d "${SPI_DEVICE}" ] && [ -d "${SPI_DRIVER}" ] || exit 0
printf '%s\n' spidev > "${SPI_DEVICE}/driver_override"
if [ ! -e "${SPI_DEVICE}/driver" ] || [ "$(readlink -f "${SPI_DEVICE}/driver")" != "${SPI_DRIVER}" ]; then
    printf '%s\n' "${SPI_NAME}" > "${SPI_DRIVER}/bind"
fi
EOF
chmod 0755 "${BIND_SCRIPT}"

cat > "${RULES_FILE}" <<EOF
# Bind SPI devices to spidev and allow spi-group access.
ACTION=="add", SUBSYSTEM=="spi", KERNEL=="spi[0-9]*.*", ATTR{driver_override}="spidev", RUN+="${BIND_SCRIPT} %k"
KERNEL=="spidev[0-9]*", GROUP="${SPI_GROUP}", MODE="0660"
EOF

udevadm control --reload-rules
udevadm trigger --subsystem-match=spi

TARGET_USER="${SUDO_USER:-}"
if [ -n "${TARGET_USER}" ] && id "${TARGET_USER}" >/dev/null 2>&1; then
    usermod -aG "${SPI_GROUP}" "${TARGET_USER}"
    echo "Added ${TARGET_USER} to the ${SPI_GROUP} group. Log out and back in for the change to take effect."
fi

echo "Installed SPI udev rules: ${RULES_FILE}"