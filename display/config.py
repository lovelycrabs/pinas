# 根据实际接线修改对应板型的引脚。GPIO 编号使用 gpiochip 的 line offset。
BOARD_CONFIG = {
    'rpi5': {'port': 0, 'cs': 0, 'dc': 25, 'rst': None, 'backlight': None},
    'rock2a': {'port': 0, 'cs': 0, 'dc': 23, 'rst': 24, 'backlight': 13},
    'rock4d': {'port': 0, 'cs': 0, 'dc': 23, 'rst': 24, 'backlight': 13},
    'rock5c': {'port': 0, 'cs': 0, 'dc': 23, 'rst': 24, 'backlight': 13},
}

BOARD = 'rpi5'
DISPLAY_CONFIG = BOARD_CONFIG[BOARD]

