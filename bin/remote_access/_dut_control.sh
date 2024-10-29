#! /usr/bin/bash
# SPDX-License-Identifier: MIT

if [[ "$(basename "$0")" == "_dut_control.sh" ]]; then
	BOARD=$1
	shift
fi

if [[ -z "${BOARD}" ]]; then
	echo "Error: Specify a board to set up." >&2
	exit 1
fi

source "${WORKDIR}/_board_helpers.sh" || exit 1

if [[ "${USE_SERVOD}" -ne 1 ]]; then
	echo "${BOARD} board does not use servod. Exiting." >&2
	exit 1
fi

if [[ -z ${SERVOD_PORT} || -z ${BOARD_NAME} ]]; then
	echo "Missing required variable. Exiting" >&2
	echo " - SERVOD_PORT: ${SERVOD_PORT}" >&2
	echo " - BOARD_NAME: ${BOARD_NAME}" >&2
	exit 1
fi

if ! _servod_is_running; then
	echo "Error: Servod for ${BOARD} is not running.  Exiting." >&2
	exit 1
fi

if [[ "${USE_SERVO_CONTAINER}" -eq 1 ]]; then
	HOSTNAME=$(hostname)
	CONTAINER_NAME="${HOSTNAME}-docker_servod_${BOARD_NAME}_${SERVOD_PORT}"

	if [[ -z "$1" ]]; then
		docker exec "${CONTAINER_NAME}" dut-control -p "${SERVOD_PORT}" --get-all
	else
		docker exec "${CONTAINER_NAME}" dut-control -p "${SERVOD_PORT}" $*
	fi
elif [[ "${USE_CROS_DIRECTORY}" -eq 1 ]]; then
	if [[ -z "${CROS_DIR}" ]]; then
		echo "Error: CROS_DIR is not set in the global config. Exiting." >&2
		exit 1
	elif [[ ! -f "${CROS_DIR}/chroot/usr/bin/dut-control" ]]; then
		echo "Error: Chroot at ${CROS_DIR} does not have dut-control in the expected location. Exiting." >&2
		exit 1
	fi

	if [[ -z "$1" ]]; then
		cd "${CROS_DIR}" && "${DEPOT_TOOLS_DIR}/cros_sdk" --no-ns-pid -- bash -c "dut-control -p ${SERVOD_PORT} --get-all"
	else
		cd "${CROS_DIR}" && "${DEPOT_TOOLS_DIR}/cros_sdk" --no-ns-pid -- bash -c "dut-control -p ${SERVOD_PORT} $*"
	fi
else
	echo "Error: No servod access method specified. Exiting." >&2
	exit 1
fi
