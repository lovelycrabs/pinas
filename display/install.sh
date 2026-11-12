#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo 'install fail!'
    echo "This script must be run as root." >&2
    exit 1
fi
disp_dir=$(cd "$(dirname "$0")" && pwd)
board=${1:-rpi5}
echo ${disp_dir}
#cp -rf ${cur_dir} /usr/local
apt install -y python3-dev libopenblas-dev
#if ! test -d "/usr/local/share/fonts/truetype"; then
#    mkdir -p /usr/local/share/fonts/truetype
#fi
#cp -f ${disp_dir}/fonts/*.ttf /usr/local/share/fonts/truetype
rm -f ${disp_dir}/config.py
cat > ${disp_dir}/config.py <<EOF
BOARD = '${board}'
BOARD_CONFIG = {
    'rpi5': {'port': 0, 'cs': 0, 'dc': 23, 'rst': 24, 'backlight': 13},
    'rock2a': {'port': 0, 'cs': 0, 'dc': 23, 'rst': 24, 'backlight': 13},
    'rock4d': {'port': 0, 'cs': 0, 'dc': 23, 'rst': 24, 'backlight': 13},
    'rock5c': {'port': 0, 'cs': 0, 'dc': 23, 'rst': 24, 'backlight': 13},
}
DISPLAY_CONFIG = BOARD_CONFIG[BOARD]
EOF
if  test -d "/sys/class/i2c-adapter/i2c-1/1-0048/hwmon"; then
    echo "lm75_device_hwmon = '/sys/class/i2c-adapter/i2c-1/1-0048/hwmon'" >> ${disp_dir}/config.py

elif test -d "/sys/class/i2c-dev/i2c-1/device/1-0048/hwmon"; then
    echo "lm75_device_hwmon = '/sys/class/i2c-dev/i2c-1/device/1-0048/hwmon'" >> ${disp_dir}/config.py

else
    echo "warning:device lm75 not found!"
fi
if  test -d "/sys/class/i2c-adapter/i2c-1/1-0040/hwmon"; then
    echo "ina226_device_hwmon = '/sys/class/i2c-adapter/i2c-1/1-0040/hwmon'" >> ${disp_dir}/config.py
elif test -d "/sys/class/i2c-dev/i2c-1/device/1-0040/hwmon"; then
    echo "ina226_device_hwmon = '/sys/class/i2c-dev/i2c-1/device/1-0040/hwmon'" >> ${disp_dir}/config.py

else
    echo "warning:device ina226 not found!"
fi
python3 -m venv ${disp_dir}/venv
${disp_dir}/venv/bin/pip install -r ${disp_dir}/requirements.txt -i https://mirrors.aliyun.com/pypi/simple
#/usr/local/display/venv/bin/python /usr/local/display/main.py
if ! test -d "/usr/local/display"; then
    mkdir -p /usr/local/display
fi
cp -rf ${disp_dir}/* /usr/local/display
cp -f ${disp_dir}/spiled.service /etc/systemd/system
systemctl enable spiled.service
systemctl start spiled.service
echo 'install path: /usr/local/display'
echo 'install success!'
