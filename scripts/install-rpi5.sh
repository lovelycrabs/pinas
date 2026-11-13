#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo 'install fail!'
    echo "This script must be run as root." >&2
    exit 1
fi

cur_dir=$(cd "$(dirname "$0")" && pwd)
repo_root=$(cd "${cur_dir}/.." && pwd)
dts_dir="${repo_root}/overlays/rpi5"
#echo ${cur_dir}
echo 'compiling dts....'
dtc -I dts -O dtb -o "${dts_dir}/pinas-sensors.dtbo" "${dts_dir}/pinas-sensors.dts"

echo 'pwm-fan dts compiled'
echo 'install dtbo'
cp -f "${dts_dir}/pinas-sensors.dtbo" /boot/firmware/overlays/
echo 'install dtbo end'
echo 'firmware config....'
cp -f /boot/firmware/config.txt /boot/firmware/config.txt.bak
#sed -i 's/#dtparam=i2c_arm=on/dtparam=i2c_arm=on/g' /boot/firmware/config.txt
#sed -i 's/#dtparam=spi=on/dtparam=spi=on/g' /boot/firmware/config.txt
#cat >> /boot/firmware/config.txt <<EOF
#dtoverlay=i2c-sensor,lm75,i2c1,addr=0x48
#dtparam=pciex1_gen=3
#dtoverlay=pciex1-compat-pi5,no-mip
#dtoverlay=pwm-fan-cpu
#dtoverlay=pwm-fan-lm75
#EOF
apt install -y python3
python3 "${repo_root}/utils/rpi5-config.py"
echo 'firmware config end'