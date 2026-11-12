# 配置dts overlay

## 1. get overlay dts

进入到overlay dts所在目录，目录结构 overlays/&lt;board&gt;/,如果树莓派:

```shell
 cd overlays/rpi5
```

## 2. install overlay

### 2.1.Raspberry Pi 树莓派

```shell
dtc -I dts -O dtb -o pinas-sensors.dtbo pinas-sensors.dts

sudo cp pinas-sensors.dtbo /boot/firmware/overlays
```

然后在/boot/firmware/config.txt追加：

```shell
dtparam=i2c_arm=on
dtoverlay=pinas-sensors
```

必须确保开启i2c dtparam=i2c_arm=on

### 2.2.raxda

```shell

dtc -I dts -O dtb -o pinas-sensors.dtbo pinas-sensors.dts

sudo cp pinas-sensors.dtbo /boot/firmware/overlays
```

或者使用 rsetup 配置管理 overlays
