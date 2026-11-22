PINAS 解压与安装说明
====================

1. 解压
将 pinas.zip 解压到开发板或其他 Linux 设备。

2. 进入目录
进入解压后的 pinas-package 目录：
  cd pinas

3. 安装依赖
  sudo apt update
  sudo apt install -y git device-tree-compiler python3

4. 运行安装
根据实际开发板选择参数：
  sudo ./install.sh -b rpi5
  sudo ./install.sh -b rock2a
  sudo ./install.sh -b rock4d
  sudo ./install.sh -b rock5c

5. 重启设备
  sudo reboot

安装前请确认 PINAS 已正确连接，开发板型号、供电、I2C 接线和风扇接线均正确。