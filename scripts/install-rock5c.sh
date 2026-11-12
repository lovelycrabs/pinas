#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo 'install fail!'
    echo "This script must be run as root." >&2
    exit 1
fi

cur_dir=$(cd "$(dirname "$0")" && pwd)
repo_root=$(cd "${cur_dir}/.." && pwd)
dts_dir="${repo_root}/overlays/rock5c"
#echo ${cur_dir}
echo 'compiling dts....'
dtc -I dts -O dtb -o "${dts_dir}/pinas-sensors.dtbo" "${dts_dir}/pinas-sensors.dts"

echo 'dts compiled'
echo 'install dtbo'
if [ -f /boot/overlays/rk3588-spi4-m2-cs0-spidev.dtbo.disabled ]; then
    mv /boot/overlays/rk3588-spi4-m2-cs0-spidev.dtbo.disabled /boot/overlays/rk3588-spi4-m2-cs0-spidev.dtbo
fi
if [ -f /boot/overlays/rk3588-i2c8-m2.dtbo.disabled ]; then
    mv /boot/overlays/rk3588-i2c8-m2.dtbo.disabled /boot/overlays/rk3588-i2c8-m2.dtbo
fi
cp -f ${dts_dir}/pinas-sensors.dtbo /boot/overlays/

echo 'install dtbo end'
echo 'install success, please reboot system!'
