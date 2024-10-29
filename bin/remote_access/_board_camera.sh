#!/usr/bin/env bash
# SPDX-License-Identifier: MIT

source "${WORKDIR}/_board_helpers.sh" || exit 1

# Get the camera name in /dev
VIDEO_DEV="$(grep -ir "${VIDEO_DEV_NAME}" /sys/class/video4linux/* 2>/dev/null | head -n 1 | sed 's|.*video|video|; s|/.*||')"

if [[ "${USE_CAMERA}" -ne 1 ]]; then
    exit 0
fi

# Error out if we didn't find the camera
if [[ -z "${VIDEO_DEV}" ]]; then
  echo "Error: No camera named ${VIDEO_DEV_NAME} found."
  exit 1
fi

# Get the capture type from the script name
CAPTYPE="$(basename "$0" | sed "s/.*${BOARD}-//; s/-.*//")"

if [[ "${CAPTYPE}" = "photo" ]]; then
    # Take a series of images to give the light levels time to adjust and the
    # camera time to focus. Delete all the unused images.
    printf "Taking snapshot..."
    sudo ffmpeg -loglevel error -f video4linux2 -i "/dev/${VIDEO_DEV}"  -vframes 20 -vf "hflip,vflip" "/tmp/${BOARD_NAME}"-screen-%3d.jpg
    printf "."
    sudo mv "/tmp/${BOARD_NAME}-screen-020.jpg" "/tmp/${BOARD_NAME}-postcode.jpg"
    printf "."
    sudo rm -f "/tmp/${BOARD_NAME}"-screen-*.jpg
    printf ". Done\n"
    printf "File is /tmp/%s-postcode.jpg\n" "${BOARD_NAME}"
elif [[ "${CAPTYPE}" = "video" ]]; then
    printf "Recording 30 seconds of video..."
    sudo ffmpeg -loglevel error -f video4linux2 -i "/dev/${VIDEO_DEV}" -t 30 -vf "hflip,vflip" "/tmp/${BOARD_NAME}"-video.mp4
    printf ". Done\n"
    printf "File is /tmp/%s-video.mp4\n" "${BOARD_NAME}"
else
    echo "Error: Unknown capture type: ${CAPTYPE}"
    exit 1
fi