#!/bin/bash
set -e

if [ "$(id -u)" -ne 0 ]; then
    echo 'install fail!'
    echo "This script must be run as root." >&2
    exit 1
fi

cur_dir=$(cd "$(dirname "$0")" && pwd)
repo_root=$(cd "${cur_dir}/.." && pwd)
dts_dir="${repo_root}/overlays/rock5c"
overlays_dir="/boot/dtbo"
i2c_dt_name="rk3588-i2c8-m2"
spi_dt_name="rk3588-spi4-m2-cs0-spidev"

echo 'checking INA226 kernel driver....'
bash "${cur_dir}/install-driver.sh"
#echo ${cur_dir}
echo 'checking INA226 kernel driver end'

echo 'install dtbo'
if [ ! -d "${overlays_dir}" ]; then
    overlays_dir="/boot/dtb/rockchip/overlay"
    mkdir -p "${overlays_dir}"
    if [ -f /boot/fnEnv.txt ]; then
        kernel_release=$(uname -r)
        kernel_series=$(printf '%s\n' "${kernel_release}" | sed -E 's/^([0-9]+\.[0-9]+).*/\1/')
        dtb_source="${repo_root}/overlays/dtbs/${kernel_series}/rk3588s-rock-5c-pinas.dtb"
        dtb_target="/boot/dtb/rockchip/rk3588s-rock-5c.dtb"
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
else
    if [ -f "${overlays_dir}/${i2c_dt_name}.dtbo.disabled" ]; then
        mv "${overlays_dir}/${i2c_dt_name}.dtbo.disabled" "${overlays_dir}/${i2c_dt_name}.dtbo"
    fi
    if [ -f "${overlays_dir}/${spi_dt_name}.dtbo.disabled" ]; then
        mv "${overlays_dir}/${spi_dt_name}.dtbo.disabled" "${overlays_dir}/${spi_dt_name}.dtbo"
    fi
    dtc -I dts -O dtb -o "${dts_dir}/pinas-sensors.dtbo" "${dts_dir}/pinas-sensors.dts"
    cp -f "${dts_dir}/pinas-sensors.dtbo" "${overlays_dir}/"

fi

echo 'install dtbo end'
