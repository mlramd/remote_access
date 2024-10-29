#!/usr/bin/bash
# SPDX-License-Identifier: MIT

source "${WORKDIR}/_board_helpers.sh" || exit 1

if [[ "${USE_USB_RELAY}" -eq 1 ]]; then
	"${HELPER_DIR}/_usb_relay_control.sh" "${BOARD}" ALL status
fi

if [[ "${USE_WEBPOWER}" -eq 1 ]]; then
	"${WORKDIR}/_webpower.sh" "${BOARD}" "status"
fi

if [[ "${USE_SERVOD}" -eq 1 ]] && _servod_is_running; then
	echo "Servod status: Running"

	BOARD_POWER_STATE="$("${WORKDIR}/_dut_control.sh" "${BOARD}" ec_system_powerstate | cut -f2 -d':')"
	echo "Power state: ${BOARD_POWER_STATE}"

	BATTERY_CHARGE="$("${WORKDIR}/_dut_control.sh" "${BOARD}" battery_charge_percent | cut -f2 -d':')"
	echo "Battery Charge: ${BATTERY_CHARGE}"

	POWER_STATUS="$("${WORKDIR}/_dut_control.sh" "${BOARD}" charger_attached | cut -f2 -d':')"
	if [[ "${POWER_STATUS}" = "True" ]]; then
		echo "Wall-power is on"
	elif [[ "${POWER_STATUS}" = "False" ]]; then
		echo "Wall-power is off."
	else
		echo "Error: Wall-power state is unknown." >&2
	fi
elif [[ "${USE_SERVOD}" -eq 1 ]]; then
	echo "Servod status: Not running."
fi

if [[ -n "${IP_ADDRESS}" ]]; then
	echo "Pinging wired ethernet ip address"
	ping -c 1 -W 1 "${IP_ADDRESS}"
fi

if [[ -n "${WIFI_IP}" ]]; then
	echo "Pinging wifi ip address"
	ping -c 1 -W 1 "${WIFI_IP}"
fi

