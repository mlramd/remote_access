#!/usr/bin/bash
# SPDX-License-Identifier: MIT

source "${WORKDIR}/_board_helpers.sh" || exit 1

if [[ "${USE_USB_RELAY}" -eq 1 ]]; then
	echo "Toggling reset button."
	"${WORKDIR}/_usb_relay_control.sh" "${BOARD}" RESET_BUTTON "toggle"
elif [[ "${USE_SERVOD}" -eq 1 ]]; then
	echo "Pressing reset button."
	"${WORKDIR}/_dut_control.sh" "${BOARD}" "cold_reset:on"
	sleep 1
	echo "Releasing reset button."
	"${WORKDIR}/_dut_control.sh" "${BOARD}" "cold_reset:off"
else
	echo "Unknown power control method. Exiting." >&2
	exit 1
fi
