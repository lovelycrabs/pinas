#!/bin/bash
set -e

if [ "$(id -u)" -ne 0 ]; then
    echo 'install fail!'
    echo "This script must be run as root." >&2
    exit 1
fi

cur_dir=$(cd "$(dirname "$0")" && pwd)
repo_root=$(cd "${cur_dir}/.." && pwd)
dts_dir="${repo_root}/overlays/rock2a"
overlays_dir="/boot/dtbo"

echo 'checking INA226 kernel driver....'
bash "${cur_dir}/install-driver.sh"
#echo ${cur_dir}

if [ ! -d "${overlays_dir}" ]; then
    overlays_dir="/boot/dtb/rockchip/overlay"
    mkdir -p "${overlays_dir}"
    if [ -f /boot/fnEnv.txt ]; then
        kernel_release=$(uname -r)
        kernel_series=$(printf '%s\n' "${kernel_release}" | sed -E 's/^([0-9]+\.[0-9]+).*/\1/')
        dtb_source="${repo_root}/overlays/dtbs/${kernel_series}/rk3528-rock-2a-pinas.dtb"
        dtb_target="/boot/dtb/rockchip/rk3528-rock-2a.dtb"
        dtb_backup="${dtb_target}.bak"
        if [ ! -f "${dtb_source}" ]; then
            echo "DTB not found for kernel series ${kernel_series}: ${dtb_source}" >&2
            exit 1
        fi
        if [ -f "${dtb_target}" ]; then
            mv -f "${dtb_target}" "${dtb_backup}"
        fi
        cp -f "${dtb_source}" "${dtb_target}"
        bash "${cur_dir}/spi-rules.sh"
    else
        echo 'board not support pinas sensors, please check your board type!'
    fi
fi

echo 'install dtbo'
if [ -f "${overlays_dir}/rk3528-i2c0-m1.dtbo.disabled" ]; then
    mv "${overlays_dir}/rk3528-i2c0-m1.dtbo.disabled" "${overlays_dir}/rk3528-i2c0-m1.dtbo"
fi
dtc -I dts -O dtb -o "${dts_dir}/rk3528-spi0-cs0-spidev.dtbo" "${dts_dir}/rk3528-spi0-cs0-spidev.dts"
cp -f "${dts_dir}/rk3528-spi0-cs0-spidev.dtbo" "${overlays_dir}/"

dtc -I dts -O dtb -o "${dts_dir}/pinas-sensors.dtbo" "${dts_dir}/pinas-sensors.dts"
cp -f "${dts_dir}/pinas-sensors.dtbo" "${overlays_dir}/"

echo 'install dtbo end'
