# RPI5 EMC2301 FAN Configuration

1. get overlay dts
Raspberry Pi 5:
```shell
 cd overlays/rpi5
```

rock2A:
```shell
 cd overlays/rock2a
```

rock5c:
```shell
 cd overlays/rock5c
```

rock4d:
```shell
 cd overlays/rock4d
```

2. install overlay

Raspberry Pi 树莓派：
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


raxda:

```shell

dtc -I dts -O dtb -o pinas-sensors.dtbo pinas-sensors.dts

sudo cp pinas-sensors.dtbo /boot/firmware/overlays
```


