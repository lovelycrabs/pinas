#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
    echo "Please run as root: sudo bash $0" >&2
    exit 1
fi

KERNEL_RELEASE="$(uname -r)"
KERNEL_BUILD="/lib/modules/${KERNEL_RELEASE}/build"
WORK_DIR="${TMPDIR:-/tmp}/pinas-ina226-${KERNEL_RELEASE}"
MODULE_PATH="/lib/modules/${KERNEL_RELEASE}/extra/ina2xx.ko"

command -v apt-get >/dev/null || { echo "apt-get is required." >&2; exit 1; }

driver_available() {
    modinfo ina2xx >/dev/null 2>&1 ||
        [[ -d /sys/bus/i2c/drivers/ina2xx ]] ||
        [[ -d /sys/module/ina2xx ]]
}

if driver_available; then
    echo "ina2xx driver is already available for ${KERNEL_RELEASE}."
    modprobe ina2xx 2>/dev/null || true
    exit 0
fi

echo "Installing kernel headers and linux-source..."
apt-get update
apt-get install -y "linux-headers-${KERNEL_RELEASE}" build-essential linux-source

if [[ ! -f "${KERNEL_BUILD}/Makefile" ]]; then
    echo "Kernel headers unavailable: ${KERNEL_BUILD}" >&2
    exit 1
fi

rm -rf "${WORK_DIR}"
mkdir -p "${WORK_DIR}"

SOURCE_ARCHIVE="$(find /usr/src -maxdepth 1 -type f \
    \( -name 'linux-source-*.tar.*' -o -name 'linux-*.tar.*' \) \
    | sort -V | tail -n 1)"

if [[ -z "${SOURCE_ARCHIVE}" ]]; then
    echo "linux-source archive was not found in /usr/src." >&2
    exit 1
fi

echo "Extracting drivers/hwmon/ina2xx.c from ${SOURCE_ARCHIVE}..."
case "${SOURCE_ARCHIVE}" in
    *.tar.xz)  tar -xJf "${SOURCE_ARCHIVE}" -C "${WORK_DIR}" --wildcards '*/drivers/hwmon/ina2xx.c' ;;
    *.tar.bz2) tar -xjf "${SOURCE_ARCHIVE}" -C "${WORK_DIR}" --wildcards '*/drivers/hwmon/ina2xx.c' ;;
    *.tar.gz)  tar -xzf "${SOURCE_ARCHIVE}" -C "${WORK_DIR}" --wildcards '*/drivers/hwmon/ina2xx.c' ;;
    *) echo "Unsupported source archive: ${SOURCE_ARCHIVE}" >&2; exit 1 ;;
esac

SOURCE_FILE="$(find "${WORK_DIR}" -path '*/drivers/hwmon/ina2xx.c' -type f | head -n 1)"
if [[ -z "${SOURCE_FILE}" ]]; then
    echo "ina2xx.c was not found in ${SOURCE_ARCHIVE}." >&2
    exit 1
fi
cp "${SOURCE_FILE}" "${WORK_DIR}/ina2xx.c"

cat > "${WORK_DIR}/Makefile" <<'EOF'
obj-m += ina2xx.o
EOF

echo "Building INA226 driver for ${KERNEL_RELEASE}..."
make -C "${KERNEL_BUILD}" M="${WORK_DIR}" modules
install -D -m 0644 "${WORK_DIR}/ina2xx.ko" "${MODULE_PATH}"
depmod -a "${KERNEL_RELEASE}"
modprobe -r ina2xx 2>/dev/null || true
modprobe ina2xx

echo "INA226 driver installed successfully: ${MODULE_PATH}"
