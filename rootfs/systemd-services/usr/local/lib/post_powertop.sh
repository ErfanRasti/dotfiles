#!/bin/bash

# Don't suspend plugged-in USB input devices

for f in $(find /sys/bus/usb/drivers/usbhid -regex '.*\/[0-9:.-]+' -printf '%f\n' | cut -d ":" -f 1 | sort -u); do
  echo on >|"/sys/bus/usb/devices/$f/power/control"
done
