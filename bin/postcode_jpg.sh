#!/usr/bin/env bash

BOARD_NAME="mayan"
VIDEO_DEV_NAME="c930e"

VIDEO_DEV="$(grep -ir "${VIDEO_DEV_NAME}" /sys/class/video4linux/* 2>/dev/null | head -n 1 | sed 's|.*video|video|; s|/.*||')"

if [[ -z "${VIDEO_DEV}" ]]; then
  echo "Error: No camera named ${VIDEO_DEV_NAME} found."
  exit 1
fi


printf "Taking snapshot..."
sudo ffmpeg -loglevel error -f video4linux2 -i "/dev/${VIDEO_DEV}"  -vframes 20 -vf "hflip,vflip" "/tmp/${BOARD_NAME}"-screen-%3d.jpg
printf "."
sudo mv "/tmp/${BOARD_NAME}-screen-020.jpg" "/tmp/${BOARD_NAME}-postcode.jpg"
printf "."
sudo rm -f "/tmp/${BOARD_NAME}"-screen-*.jpg
printf ". Done\n"
printf "File is /tmp/${BOARD_NAME}-postcode.jpg\n"

