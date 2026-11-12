# PINAS

## 简介

PINAS 支持树莓派5、RAXDA Rock2A、RAXDA Rock4D、RAXDA Rock5C开发板。

支持飞牛NAS系统（FN-OS），下载地址：<https://fnnas.com/download-arm>

[安装配置](#安装指南)

[购买链接](<https://www.goofish.com/item?spm=a21ybx.search.searchFeedList.1.65e033bbsNMF3L&id=877258687346&categoryId=126856550>)

![示意图](images/image1.jpg)
![示意图](images/image2.jpg)
![示意图](images/image3.jpg)
![示意图](images/image4.jpg)

## 安装指南

### 1. 准备系统和依赖

先为开发板安装对应的 FN-OS ARM 系统，完成首次启动和网络配置，然后通过 SSH 或本地终端登录。以下命令在开发板上执行。

安装脚本需要 Bash、设备树编译器 `dtc`；树莓派配置还需要 Python 3。使用 `apt` 的系统可执行：

```shell
sudo apt update
sudo apt install -y git device-tree-compiler python3
```

脚本会写入启动分区，需要使用 `sudo`，并确保启动分区可写。树莓派使用 `/boot/firmware/overlays/` 和 `/boot/firmware/config.txt`，Rock 系列使用 `/boot/overlays/`。如果系统中的路径不同，请先确认系统的设备树加载方式。

### 2. 下载项目

```shell
git clone https://github.com/zengqingzheng/pinas.git
cd pinas
```

如果 GitHub 无法访问，可以使用镜像：[https://gitee.com/zengqingzheng/pinas.git](https://gitee.com/zengqingzheng/pinas.git)。

为安装脚本添加执行权限：

```shell
sudo chmod +x install.sh
```

后续安装命令均在 `pinas` 项目根目录执行。

### 3. 选择开发板并安装

`-b` 指定开发板，参数必须与实际硬件一致：

| 开发板 | board 参数 | 安装命令 |
| --- | --- | --- |
| 树莓派 5 | `rpi5` | `sudo ./install.sh -b rpi5` |
| Radxa ROCK 2A | `rock2a` | `sudo ./install.sh -b rock2a` |
| Radxa ROCK 4D | `rock4d` | `sudo ./install.sh -b rock4d` |
| Radxa ROCK 5C | `rock5c` | `sudo ./install.sh -b rock5c` |

只需执行对应开发板的一条命令。例如 ROCK 2A：

```shell
sudo ./install.sh -b rock2a
```

也支持 `--board rock2a` 和 `--board=rock2a`。不指定参数时默认安装树莓派 5 配置。查看帮助：

```shell
./install.sh --help
```

安装脚本会编译对应的 `pinas-sensors.dts`，并复制生成的 `pinas-sensors.dtbo` 到启动分区。

- **树莓派 5**：先将 `/boot/firmware/config.txt` 备份到 `config.txt.bak`，再配置 I²C、SPI、PCIe 和 `pinas-sensors` overlay。重复安装会覆盖该备份，如需保留原始配置，请另行备份。
- **Rock 系列**：如果对应的 I²C/SPI overlay 存在 `.dtbo.disabled` 文件，脚本会将其恢复为 `.dtbo`；源文件不存在时跳过。脚本只复制 PINAS overlay 并恢复这些文件名，不会自动修改启动配置。请使用系统提供的 `rsetup` 或启动配置方式，确认所需 I²C/SPI 及 `pinas-sensors` overlay 已启用。

手动配置可参考 [设备树 overlay 说明](overlays/README.md)。

### 4. 重启并检查

先检查安装输出中是否有编译、复制或配置错误；脚本末尾的成功提示不能代替这些检查。确认无误后重启：

```shell
sudo reboot
```

重新登录后，检查 overlay 文件和内核日志：

```shell
# 树莓派 5
ls -l /boot/firmware/overlays/pinas-sensors.dtbo

# Rock 系列
ls -l /boot/overlays/pinas-sensors.dtbo

# 查看传感器和风扇驱动相关日志
sudo dmesg | grep -Ei 'pinas|lm75|ina226|emc2301|fan|thermal'
```

overlay 文件存在仅表示已经复制，是否加载成功还需结合启动配置、内核日志及实际温度读取、风扇运行情况判断。

### 常见问题

- **`dtc: command not found`**：安装 `device-tree-compiler` 后重新执行。
- **提示必须以 root 运行**：在安装命令前添加 `sudo`。
- **`unsupported board`**：使用上表中的小写参数，可通过 `--help` 查看支持列表。
- **提示启动目录或配置文件不存在**：核对当前系统的启动分区挂载位置，不要仅创建空目录后继续安装。
- **重启后没有传感器或风扇功能**：确认选择了正确板型、overlay 已启用，并检查硬件连接、内核驱动和 `dmesg` 中的错误。
