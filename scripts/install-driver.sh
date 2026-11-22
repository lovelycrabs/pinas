#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
    echo "Please run as root: sudo bash $0" >&2
    exit 1
fi

KERNEL_RELEASE="$(uname -r)"
KERNEL_BUILD="/lib/modules/${KERNEL_RELEASE}/build"
WORK_DIR="${TMPDIR:-/tmp}/pinas-hwmon-${KERNEL_RELEASE}"
MODULE_DIR="/lib/modules/${KERNEL_RELEASE}/kernel/drivers/hwmon"
DRIVERS=(ina2xx lm75 emc2305)

command -v apt-get >/dev/null || { echo "apt-get is required." >&2; exit 1; }
configure_emc2305_autoload() {
    local modules_load_conf="/etc/modules-load.d/emc2305.conf"
    install -d -m 0755 /etc/modules-load.d
    printf '%s\n' emc2305 > "${modules_load_conf}"
}

driver_available() {
    local driver="$1"
    modinfo "${driver}" >/dev/null 2>&1 ||
        [[ -d "/sys/bus/i2c/drivers/${driver}" ]] ||
        [[ -d "/sys/module/${driver}" ]]
}

MISSING_DRIVERS=()
for driver in "${DRIVERS[@]}"; do
    if driver_available "${driver}"; then
        echo "${driver} driver is already available for ${KERNEL_RELEASE}."
        modprobe "${driver}" 2>/dev/null || true
    else
        MISSING_DRIVERS+=("${driver}")
    fi
done

if [[ "${#MISSING_DRIVERS[@]}" -eq 0 ]]; then
    configure_emc2305_autoload
    modprobe emc2305 2>/dev/null || true
    exit 0
fi

echo "Installing kernel headers and download tools..."
apt-get update
apt-get install -y "linux-headers-${KERNEL_RELEASE}" build-essential ca-certificates curl

if [[ ! -f "${KERNEL_BUILD}/Makefile" ]]; then
    echo "Kernel headers unavailable: ${KERNEL_BUILD}" >&2
    exit 1
fi

rm -rf "${WORK_DIR}"
mkdir -p "${WORK_DIR}"

KERNEL_VERSION="$(printf '%s\n' "${KERNEL_RELEASE}" | sed -E 's/^([0-9]+\.[0-9]+\.[0-9]+).*/\1/')"
SOURCE_DIR="$(pwd)"
SOURCE_ARCHIVE="${SOURCE_DIR}/linux-${KERNEL_VERSION}.tar.xz"

if [[ ! -f "${SOURCE_ARCHIVE}" ]]; then
    SOURCE_URL="https://mirrors.aliyun.com/linux-kernel/v${KERNEL_VERSION%%.*}.x/linux-${KERNEL_VERSION}.tar.xz"
    echo "Linux source not found in ${SOURCE_DIR}; downloading ${SOURCE_URL}..."
    curl --fail --location --retry 3 --output "${SOURCE_ARCHIVE}" "${SOURCE_URL}"
else
    echo "Using Linux source archive: ${SOURCE_ARCHIVE}"
fi

SOURCE_ROOT="$(tar -tf "${SOURCE_ARCHIVE}" | awk -F/ 'NF > 1 && !found { print $1; found=1 }')"
if [[ -z "${SOURCE_ROOT}" ]]; then
    echo "Unable to determine the source root in ${SOURCE_ARCHIVE}." >&2
    exit 1
fi

echo "Extracting drivers: ${MISSING_DRIVERS[*]}..."
SOURCE_FILES=()
for driver in "${MISSING_DRIVERS[@]}"; do
    SOURCE_FILES+=("${SOURCE_ROOT}/drivers/hwmon/${driver}.c")
    if [[ "${driver}" == "lm75" ]]; then
        SOURCE_FILES+=("${SOURCE_ROOT}/drivers/hwmon/lm75.h")
    fi
done
tar -xJf "${SOURCE_ARCHIVE}" -C "${WORK_DIR}" "${SOURCE_FILES[@]}"

: > "${WORK_DIR}/Makefile"
for driver in "${MISSING_DRIVERS[@]}"; do
    cp "${WORK_DIR}/${SOURCE_ROOT}/drivers/hwmon/${driver}.c" "${WORK_DIR}/${driver}.c"
    if [[ "${driver}" == "lm75" ]]; then
        cp "${WORK_DIR}/${SOURCE_ROOT}/drivers/hwmon/lm75.h" "${WORK_DIR}/lm75.h"
    fi
    printf 'obj-m += %s.o\n' "${driver}" >> "${WORK_DIR}/Makefile"
done

echo "Building drivers for ${KERNEL_RELEASE}: ${MISSING_DRIVERS[*]}..."
make -C "${KERNEL_BUILD}" M="${WORK_DIR}" modules

for driver in "${MISSING_DRIVERS[@]}"; do
    install -D -m 0644 "${WORK_DIR}/${driver}.ko" "${MODULE_DIR}/${driver}.ko"
done

depmod -a "${KERNEL_RELEASE}"
configure_emc2305_autoload
for driver in "${MISSING_DRIVERS[@]}"; do
    modprobe -r "${driver}" 2>/dev/null || true
    modprobe "${driver}"
    echo "${driver} driver installed successfully: ${MODULE_DIR}/${driver}.ko"
done