#!/usr/bin/bash
# SPDX-License-Identifier: MIT

if [[ -n "${DEBUG}" ]]; then set -x; fi

if [[ -z "${WORKDIR}" ]]; then
	SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd | sed 's|/remote_access.*||')
	export WORKDIR="${SCRIPT_DIR}/remote_access"
fi

if [[ -z "${BOARD}" ]]; then
	BOARD="$(basename "$0" | sed 's/-.*//')"
fi

if [[ -f "/etc/remote_access.conf" ]]; then
	source "/etc/remote_access.conf" || exit 1
elif [[ -f "${WORKDIR}/remote_access.conf" ]]; then
	source "${WORKDIR}/remote_access.conf" || exit 1
else
	echo "Error: Could not locate remote access config file. Exiting." >&2
	exit 1
fi

BOARD_CONFIG="${CONFIG_DIR}/${BOARD}_config"

if [[ -f "${BOARD_CONFIG}" ]]; then
	source "${BOARD_CONFIG}" || exit 1
else
	echo "Error: Could not locate ${BOARD_CONFIG}. Exiting." >&2
	exit 1
fi

if [[ "${USE_CROS_DIRECTORY}" -eq 1 ]]; then
	if [[ -z "${CROS_DIR}" || ! -d "${CROS_DIR}" ]]; then
		echo "Error: CROS_DIR variable is invalid or unset: '${CROS_DIR}'. Exiting."
		exit 1
	fi
	DEPOT_TOOLS_DIR="$(dirname "$(command -v cros_sdk)")"
	if [[ -z "${DEPOT_TOOLS_DIR}" ]]; then
		echo "Error: Depot tools directory is not in your path. Exiting."
		exit 1
	fi
	export DEPOT_TOOLS_DIR
fi

if [[ -z "${LOG_DIR}" ]]; then
	export LOG_DIR="/tmp/${BOARD}_logs"
	mkdir -p "${LOG_DIR}"
fi

export BOARD

_get_pty() {
	local uart=$1

	if [[ "${uart}" = "ap" ]]; then
		USBSERIALNO="${AP_UART_SERIAL}"
	elif [[ "${uart}" = "ec" ]]; then
		USBSERIALNO="${EC_UART_SERIAL}"
	fi

	if [[ ${USE_FTDI_SERIAL} -eq 1 ]]; then
		if [[ -n "${USBSERIALNO}" ]]; then
			USBSERIALPATH="$(grep -r "${USBSERIALNO}" /sys/devices 2>/dev/null | sed 's|serial:.*||')"
		else
			echo "Error: No USB serial number provided for ${uart}. Exiting." >&2
			exit 1
		fi

		if [[ -n "${USBSERIALPATH}" ]]; then
			PTY="/dev/$(find "${USBSERIALPATH}" -name "ttyUSB*" 2>/dev/null | head -n 1 | sed 's|.*/||')"
		else
			echo "Error: Could not find USB serial device for ${uart}. Exiting." >&2
			exit 1
		fi
	elif [[ -e /dev/${BOARD}_${uart^^} ]]; then
		PTY="$(readlink "/dev/${BOARD}_${uart^^}")"
	elif [[ -n "${USE_SERVOD}" && -n "${uart}" ]]; then
		PTY="$("${WORKDIR}/_dut_control.sh" "${BOARD}" "${uart,,}_uart_pty" | sed 's/.*://')"
	else
		echo "Error: Cannot determine PTY." >&2
		exit 1
	fi
	export PTY
}

_servod_is_running() {
	if [[ "${USE_SERVO_CONTAINER}" -eq 1 ]]; then
		HOSTNAME=$(hostname)
		CONTAINER_NAME="${HOSTNAME}-docker_servod_${BOARD_NAME}_${SERVOD_PORT}"
		docker ps | grep -q "${CONTAINER_NAME}"
	else
		nc -t -z localhost "${SERVOD_PORT}"
	fi
}

check_for_cmd() {
	CMD=$1
	if [[ -z "$(command -v ${CMD})" ]]; then
		echo "Error: ${CMD} is not installed." >&2
		echo "Please install it with your package manager. Exiting." >&2
		exit 1
	fi
}

check_group() {
	GRP=$1
	if [[ -z "$(groups | grep "${GRP}")" ]]; then
		echo "Error: User ${USER} is not in group ${GRP}." >&2
		echo "Please run 'sudo usermod -a -G ${GRP} ${USER}'" >&2
		echo "Exiting." >&2
		exit 1
	fi
}
