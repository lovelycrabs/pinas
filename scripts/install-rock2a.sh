#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo 'install fail!'
    echo "This script must be run as root." >&2
    exit 1
fi

cur_dir=$(cd "$(dirname "$0")" && pwd)
repo_root=$(cd "${cur_dir}/.." && pwd)
dts_dir="${repo_root}/overlays/rock2a"
#echo ${cur_dir}
echo 'compiling dts....'
dtc -I dts -O dtb -o "${dts_dir}/pinas-sensors.dtbo" "${dts_dir}/pinas-sensors.dts"

echo 'dts compiled'
echo 'install dtbo'
if [ -f /boot/overlays/rk3528-i2c0-m1.dtbo.disabled ]; then
    mv /boot/overlays/rk3528-i2c0-m1.dtbo.disabled /boot/overlays/rk3528-i2c0-m1.dtbo
fi
if [ -f /boot/overlays/rk3528-spi0-cs1-spidev.dtbo.disabled ]; then
    mv /boot/overlays/rk3528-spi0-cs1-spidev.dtbo.disabled /boot/overlays/rk3528-spi0-cs1-spidev.dtbo
fi
cp -f ${dts_dir}/pinas-sensors.dtbo /boot/overlays/

echo 'install dtbo end'
echo 'install success, please reboot system!'
