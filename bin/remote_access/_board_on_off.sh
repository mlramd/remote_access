#!/usr/bin/bash
# SPDX-License-Identifier: MIT

source "${WORKDIR}/_board_helpers.sh" || exit 1

POWER_STATE="$(echo "$0" | grep "${BOARD}-" | sed 's/.*-//')"

if [[ "${POWER_STATE,,}" = "on" ]]; then
	DELAY=.5
elif [[ "${POWER_STATE,,}" = "off" ]]; then
	DELAY=9
else
	echo "Error: Unknown powerstate '${POWER_STATE}'. Exiting." >&2
	exit 1
fi	

if [[ "${USE_USB_RELAY}" -eq 1 ]]; then
	echo "Pressing power button."
	"${WORKDIR}/_usb_relay_control.sh" "${BOARD}" POWER_BUTTON "${POWER_STATE}"
	echo "Power button released."
elif [[ "${USE_SERVOD}" -eq 1 ]]; then
	if [[ -z "${PWR_BTN_PRESS_CMD}" ]]; then
		PWR_BTN_PRESS_CMD="pwr_button:press"
	fi
	if [[ -z "${PWR_BTN_RELEASE_CMD}" ]]; then
		PWR_BTN_RELEASE_CMD="pwr_button:release"
	fi

	echo "Pressing power button"
	"${WORKDIR}/_dut_control.sh" "${BOARD}" "${PWR_BTN_PRESS_CMD}"
	echo "Delaying ${DELAY} seconds."
	sleep "${DELAY}"
	echo "Releasing power button"
	"${WORKDIR}/_dut_control.sh" "${BOARD}" "${PWR_BTN_RELEASE_CMD}" warm_reset:off
else
	echo "Unknown power control method. Exiting." >&2
	exit 1
fi
