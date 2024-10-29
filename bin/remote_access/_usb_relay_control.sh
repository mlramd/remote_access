#!/usr/bin/bash
# SPDX-License-Identifier: MIT

if [[ -n "${DEBUG}" ]]; then set -x; fi

BOARD=$1
RELAY_NAME=$2
POWER_STATE=${3,,}

source "${WORKDIR}/_board_helpers.sh" || exit 1

if [[ -z "${BOARD}" ]]; then
	echo "Board name must be specified. Exiting."
	exit 1
elif [[ "${POWER_STATE}" != "status" && "${POWER_STATE}" != "on" && "${POWER_STATE}" != "off" && "${POWER_STATE}" != "toggle" ]]; then
	echo "Power state must be 'status', 'on, 'off', or 'toggle'. Exiting." >&2
	exit 1
elif [[ -z ${RELAY_NAME} ]]; then
	echo "RELAY_NAME not specified. Exiting" >&2
	exit 1
fi

if [[ -z "${USE_USB_RELAY}" ]]; then
	echo "${BOARD} board does not use a relay board. Exiting."
	exit 1
elif [[ -z ${USB_RELAY_SERIAL} ]]; then
	echo "USB_RELAY_SERIAL is not set in ${BOARD}_config. Exiting." >&2
	exit 1
fi

case ${RELAY_NAME} in
ALL)
	echo "Showing status"
	;;
POWER_BUTTON)
	if [[ -n "${USB_RELAY_POWER_SWITCH}" ]]; then
		sudo relay "${USB_RELAY_SERIAL}" "${USB_RELAY_POWER_SWITCH}" 0x00 >/dev/null

		if [[ "${POWER_STATE}" = "on" ]]; then
			sleep 2
		elif [[ "${POWER_STATE}" = "off" ]]; then
			sleep 5
		else # Toggle
			sleep 1
		fi

		sudo relay "${USB_RELAY_SERIAL}" 0x00 "${USB_RELAY_POWER_SWITCH}" >/dev/null
	else
		echo "Error: No power switch set" >&2
		exit 1
	fi
	;;
RESET_BUTTON)
	if [[ "${POWER_STATE}" = "on" ]]; then
		sudo relay "${USB_RELAY_SERIAL}" "${USB_RELAY_COLD_RESET_SWITCH}" 0x00 >/dev/null
	elif [[ "${POWER_STATE}" = "off" ]]; then
		sudo relay "${USB_RELAY_SERIAL}" 0x00 "${USB_RELAY_COLD_RESET_SWITCH}" >/dev/null
	else # Toggle
		if [[ -n "${USB_RELAY_COLD_RESET_SWITCH}" ]]; then
			sudo relay "${USB_RELAY_SERIAL}" "${USB_RELAY_COLD_RESET_SWITCH}" 0x00 >/dev/null
			sleep 2
			sudo relay "${USB_RELAY_SERIAL}" 0x00 "${USB_RELAY_COLD_RESET_SWITCH}" >/dev/null
		else
			echo "Error: No cold reset switch set" >&2
			exit 1
		fi
	fi
	;;
RESET_DEDIPROG)
	if [[ "${POWER_STATE}" = "on" ]]; then
		sudo relay "${USB_RELAY_SERIAL}" "${USB_RELAY_RESET_DEDIPROG}" 0x00 >/dev/null
	elif [[ "${POWER_STATE}" = "off" ]]; then
		sudo relay "${USB_RELAY_SERIAL}" 0x00 "${USB_RELAY_RESET_DEDIPROG}" >/dev/null
	else # Toggle
		if [[ -n "${USB_RELAY_RESET_DEDIPROG}" ]]; then
			sudo relay "${USB_RELAY_SERIAL}" "${USB_RELAY_RESET_DEDIPROG}" 0x00 >/dev/null
			sleep 4
			sudo relay "${USB_RELAY_SERIAL}" 0x00 "${USB_RELAY_RESET_DEDIPROG}" >/dev/null
		else
			echo "Error: No dediprog reset switch set" >&2
			exit 1
		fi
	fi
	exit 0
	;;
*)
	echo "Error: ${RELAY_NAME} is not used." >&2
	echo "Valid relay names are ALL, POWER_BUTTON and RESET_BUTTON." >&2
	exit 1
	;;

esac

STATUS=$(sudo relay "${USB_RELAY_SERIAL}")

if [[ -n "${USB_RELAY_BOARD_POWER}" ]]; then
	if [[ $((STATUS & USB_RELAY_BOARD_POWER)) != 0 ]]; then
		echo "Board has power"
	else
		echo "Board has no power"
	fi
fi
if [[ -n "${USB_RELAY_BOARD_ON}" ]]; then
	if [[ $((STATUS & USB_RELAY_BOARD_ON)) != 0 ]]; then
		echo "Board is on"
	else
		echo "Board is off"
	fi
fi
