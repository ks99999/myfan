#!/bin/bash

stop_myfan(){
  local screens=(`screen -ls myfan | grep -Po "\K[0-9]+(?=\.myfan)" | sort --unique`)
  for pid in "${screens[@]}"; do
    timeout 1 screen -S $pid.myfan -X quit
  done
}

stop_myfan
/usr/bin/avrdude -p m328p -c arduino -P /dev/ttyACM0 -b 57600 -U flash:w:myfan3.ino.hex:i
hello
