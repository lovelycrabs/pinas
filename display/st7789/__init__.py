# Copyright (c) 2014 Adafruit Industries
# Author: Tony DiCola
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
import numbers
import time

import gpiod
import gpiodevice
import spidev
from gpiod.line import Direction, Value
from .font import FONT

__version__ = "1.0.1"

OUTL = gpiod.LineSettings(direction=Direction.OUTPUT, output_value=Value.INACTIVE)
OUTH = gpiod.LineSettings(direction=Direction.OUTPUT, output_value=Value.ACTIVE)

BG_SPI_CS_BACK = 0
BG_SPI_CS_FRONT = 1

SPI_CLOCK_HZ = 16000000

ST7789_NOP = 0x00
ST7789_SWRESET = 0x01
ST7789_RDDID = 0x04
ST7789_RDDST = 0x09

ST7789_SLPIN = 0x10
ST7789_SLPOUT = 0x11
ST7789_PTLON = 0x12
ST7789_NORON = 0x13

ST7789_INVOFF = 0x20
ST7789_INVON = 0x21
ST7789_DISPOFF = 0x28
ST7789_DISPON = 0x29

ST7789_CASET = 0x2A
ST7789_RASET = 0x2B
ST7789_RAMWR = 0x2C
ST7789_RAMRD = 0x2E

ST7789_PTLAR = 0x30
ST7789_MADCTL = 0x36
ST7789_COLMOD = 0x3A

ST7789_FRMCTR1 = 0xB1
ST7789_FRMCTR2 = 0xB2
ST7789_FRMCTR3 = 0xB3
ST7789_INVCTR = 0xB4
ST7789_DISSET5 = 0xB6

ST7789_GCTRL = 0xB7
ST7789_GTADJ = 0xB8
ST7789_VCOMS = 0xBB

ST7789_LCMCTRL = 0xC0
ST7789_IDSET = 0xC1
ST7789_VDVVRHEN = 0xC2
ST7789_VRHS = 0xC3
ST7789_VDVS = 0xC4
ST7789_VMCTR1 = 0xC5
ST7789_FRCTRL2 = 0xC6
ST7789_CABCCTRL = 0xC7

ST7789_RDID1 = 0xDA
ST7789_RDID2 = 0xDB
ST7789_RDID3 = 0xDC
ST7789_RDID4 = 0xDD

ST7789_GMCTRP1 = 0xE0
ST7789_GMCTRN1 = 0xE1

ST7789_PWCTR6 = 0xFC


class ST7789(object):
    """Representation of an ST7789 TFT LCD."""

    def __init__(
        self,
        port,
        cs,
        dc,
        backlight=None,
        rst=None,
        width=240,
        height=240,
        rotation=90,
        invert=True,
        spi_speed_hz=4000000,
        offset_left=0,
        offset_top=0,
    ):
        """Create an instance of the display using SPI communication.

        Must provide the GPIO pin number for the D/C pin and the SPI driver.

        Can optionally provide the GPIO pin number for the reset pin as the rst parameter.

        :param port: SPI port number
        :param cs: SPI chip-select number (0 or 1 for BCM
        :param backlight: Pin for controlling backlight
        :param rst: Reset pin for ST7789
        :param width: Width of display connected to ST7789
        :param height: Height of display connected to ST7789
        :param rotation: Rotation of display connected to ST7789
        :param invert: Invert display
        :param spi_speed_hz: SPI speed (in Hz)

        """
        if rotation not in [0, 90, 180, 270]:
            raise ValueError(f"Invalid rotation {rotation}")

        if width != height and rotation in [90, 270]:
            raise ValueError(
                f"Invalid rotation {rotation} for {width}x{height} resolution"
            )

        gpiodevice.friendly_errors = True

        self._spi = spidev.SpiDev(port, cs)
        self._spi.mode = 0
        self._spi.lsbfirst = False
        self._spi.max_speed_hz = spi_speed_hz

        self._dc = dc
        self._rst = rst
        self._width = width
        self._height = height
        self._rotation = rotation
        self._invert = invert

        self._offset_left = offset_left
        self._offset_top = offset_top

        # Set DC as output.
        self._dc = gpiodevice.get_pin(dc, "st7789-dc", OUTL)

        # Setup backlight as output (if provided).
        if backlight is not None:
            self._bl = gpiodevice.get_pin(backlight, "st7789-bl", OUTL)
            self.set_pin(self._bl, False)
            time.sleep(0.1)
            self.set_pin(self._bl, True)

        # Setup reset as output (if provided).
        if rst is not None:
            self._rst = gpiodevice.get_pin(rst, "st7789-rst", OUTH)

        self._init()

    def set_pin(self, pin, state):
        lines, offset = pin
        lines.set_value(offset, Value.ACTIVE if state else Value.INACTIVE)

    def send(self, data, is_data=True, chunk_size=4096):
        """Write a byte or array of bytes to the display. Is_data parameter
        controls if byte should be interpreted as display data (True) or command
        data (False).  Chunk_size is an optional size of bytes to write in a
        single SPI transaction, with a default of 4096.
        """
        # Set DC low for command, high for data.
        self.set_pin(self._dc, is_data)
        # Convert scalar argument to list so either can be passed as parameter.
        if isinstance(data, numbers.Number):
            data = [data & 0xFF]
        # Write data a chunk at a time.
        for start in range(0, len(data), chunk_size):
            end = min(start + chunk_size, len(data))
            self._spi.xfer(data[start:end])

    def set_backlight(self, value):
        """Set the backlight on/off."""
        if self._bl is not None:
            self.set_pin(self._bl, value)

    @property
    def width(self):
        return (
            self._width
            if self._rotation == 0 or self._rotation == 180
            else self._height
        )

    @property
    def height(self):
        return (
            self._height
            if self._rotation == 0 or self._rotation == 180
            else self._width
        )

    def command(self, data):
        """Write a byte or array of bytes to the display as command data."""
        self.send(data, False)

    def data(self, data):
        """Write a byte or array of bytes to the display as display data."""
        self.send(data, True)

    def reset(self):
        """Reset the display, if reset pin is connected."""
        if self._rst is not None:
            self.set_pin(self._rst, True)
            time.sleep(0.500)
            self.set_pin(self._rst, False)
            time.sleep(0.500)
            self.set_pin(self._rst, True)
            time.sleep(0.500)

    def _init(self):
        # Initialize the display.

        self.command(ST7789_SWRESET)  # Software reset
        time.sleep(0.150)  # delay 150 ms

        self.command(ST7789_MADCTL)
        self.data(0x70)

        self.command(ST7789_FRMCTR2)  # Frame rate ctrl - idle mode
        self.data(0x0C)
        self.data(0x0C)
        self.data(0x00)
        self.data(0x33)
        self.data(0x33)

        self.command(ST7789_COLMOD)
        self.data(0x05)

        self.command(ST7789_GCTRL)
        self.data(0x14)

        self.command(ST7789_VCOMS)
        self.data(0x37)

        self.command(ST7789_LCMCTRL)  # Power control
        self.data(0x2C)

        self.command(ST7789_VDVVRHEN)  # Power control
        self.data(0x01)

        self.command(ST7789_VRHS)  # Power control
        self.data(0x12)

        self.command(ST7789_VDVS)  # Power control
        self.data(0x20)

        self.command(0xD0)
        self.data(0xA4)
        self.data(0xA1)

        self.command(ST7789_FRCTRL2)
        self.data(0x0F)

        self.command(ST7789_GMCTRP1)  # Set Gamma
        self.data(0xD0)
        self.data(0x04)
        self.data(0x0D)
        self.data(0x11)
        self.data(0x13)
        self.data(0x2B)
        self.data(0x3F)
        self.data(0x54)
        self.data(0x4C)
        self.data(0x18)
        self.data(0x0D)
        self.data(0x0B)
        self.data(0x1F)
        self.data(0x23)

        self.command(ST7789_GMCTRN1)  # Set Gamma
        self.data(0xD0)
        self.data(0x04)
        self.data(0x0C)
        self.data(0x11)
        self.data(0x13)
        self.data(0x2C)
        self.data(0x3F)
        self.data(0x44)
        self.data(0x51)
        self.data(0x2F)
        self.data(0x1F)
        self.data(0x1F)
        self.data(0x20)
        self.data(0x23)

        if self._invert:
            self.command(ST7789_INVON)  # Invert display
        else:
            self.command(ST7789_INVOFF)  # Don't invert display

        self.command(ST7789_SLPOUT)

        self.command(ST7789_DISPON)  # Display on
        time.sleep(0.100)  # 100 ms

    def begin(self):
        """Set up the display

        Deprecated. Included in __init__.

        """
        pass

    def set_window(self, x0=0, y0=0, x1=None, y1=None):
        """Set the pixel address window for proceeding drawing commands. x0 and
        x1 should define the minimum and maximum x pixel bounds.  y0 and y1
        should define the minimum and maximum y pixel bound.  If no parameters
        are specified the default will be to update the entire display from 0,0
        to width-1,height-1.
        """
        if x1 is None:
            x1 = self._width - 1

        if y1 is None:
            y1 = self._height - 1

        y0 += self._offset_top
        y1 += self._offset_top

        x0 += self._offset_left
        x1 += self._offset_left

        self.command(ST7789_CASET)  # Column addr set
        self.data(x0 >> 8)
        self.data(x0 & 0xFF)  # XSTART
        self.data(x1 >> 8)
        self.data(x1 & 0xFF)  # XEND
        self.command(ST7789_RASET)  # Row addr set
        self.data(y0 >> 8)
        self.data(y0 & 0xFF)  # YSTART
        self.data(y1 >> 8)
        self.data(y1 & 0xFF)  # YEND
        self.command(ST7789_RAMWR)  # write to RAM

    @staticmethod
    def __build_color_buffer(color, pixel_size):
        buff = bytearray(pixel_size*2)
        for i in range(0, len(buff), 2):
            buff[i] = (color[0]&0xF8)|(color[1]>>5)
            buff[i+1] = ((color[1]&0x1C)<<3)|(color[2]>>3)
        return buff




    def fill_rect(self, color=(0,0,0,), x=0, y=0, w=None, h=None):
        if w is None:
            w = self._width
        if h is None:
            h = self._height
        self.set_window(x, y, x+w-1, y+h-1)
        pixel_buff = self.__build_color_buffer(color, w*h)
        self.data(pixel_buff)

    def pixel(self, x, y, color=(255, 255, 255)):
        """Draw one pixel; coordinates outside the screen are clipped."""
        if 0 <= x < self._width and 0 <= y < self._height:
            self.fill_rect(color, x, y, 1, 1)

    def line(self, x0, y0, x1, y1, color=(255, 255, 255)):
        """Draw an inclusive line using integer coordinates."""
        dx, dy = abs(x1-x0), -abs(y1-y0)
        sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
        error = dx + dy
        while True:
            self.pixel(x0, y0, color)
            if x0 == x1 and y0 == y1:
                break
            twice = 2 * error
            if twice >= dy:
                error += dy
                x0 += sx
            if twice <= dx:
                error += dx
                y0 += sy

    def rect(self, x, y, w, h, color=(255, 255, 255), fill=False):
        """Draw an outlined or filled rectangle with screen clipping."""
        if w <= 0 or h <= 0:
            return
        if fill:
            left, top = max(0, x), max(0, y)
            right, bottom = min(self._width, x+w), min(self._height, y+h)
            if right > left and bottom > top:
                self.fill_rect(color, left, top, right-left, bottom-top)
            return
        self.line(x, y, x+w-1, y, color)
        self.line(x, y+h-1, x+w-1, y+h-1, color)
        self.line(x, y, x, y+h-1, color)
        self.line(x+w-1, y, x+w-1, y+h-1, color)

    def circle(self, x, y, radius, color=(255, 255, 255), fill=False):
        """Draw a circle; radius must be a non-negative integer."""
        if not isinstance(radius, int) or radius < 0:
            raise ValueError('radius must be a non-negative integer')
        cx, cy, error = radius, 0, 1-radius
        while cx >= cy:
            if fill:
                for offset, half in ((cy, cx), (-cy, cx), (cx, cy), (-cx, cy)):
                    self.rect(x-half, y+offset, 2*half+1, 1, color, True)
            else:
                for ox, oy in ((cx, cy), (cy, cx), (-cy, cx), (-cx, cy),
                               (-cx, -cy), (-cy, -cx), (cy, -cx), (cx, -cy)):
                    self.pixel(x+ox, y+oy, color)
            cy += 1
            if error < 0:
                error += 2*cy+1
            else:
                cx -= 1
                error += 2*(cy-cx)+1

    def text(self, text, x=0, y=0, color=(255, 255, 255),
             background=(0, 0, 0), scale=1, w=None, h=None):
        """Draw opaque 5x7 text. Lowercase maps to uppercase; supports newlines."""
        lines = str(text).split('\n')
        w = max(1, max(map(len, lines)) * 6 * scale) if w is None else w
        h = len(lines) * 8 * scale if h is None else h
        if not isinstance(scale, int) or scale < 1:
            raise ValueError('scale must be a positive integer')
        if w <= 0 or h <= 0:
            raise ValueError('width and height must be positive')
        self.rect(x, y, w, h, background, True)
        for li, line in enumerate(lines):
            for ci, ch in enumerate(line):
                for row, bits in enumerate(FONT.get(ch.upper(), FONT['?'])):
                    for col in range(5):
                        if bits & (1 << (4-col)):
                            px, py = (ci*6+col)*scale, (li*8+row)*scale
                            if px < w and py < h:
                                self.rect(x+px, y+py, min(scale, w-px),
                                          min(scale, h-py), color, True)
