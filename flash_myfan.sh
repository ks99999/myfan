#!/bin/bash
/usr/bin/avrdude -p m328p -c arduino -P /dev/ttyACM0 -b 57600 -U flash:w:myfan3.ino.hex:i
