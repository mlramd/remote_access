#!/usr/bin/bash
# SPDX-License-Identifier: MIT

RESTART=$1
source "${WORKDIR}/_board_helpers.sh" || exit 1

if [[ "${USE_SERVOD}" -ne 1 ]]; then
	echo "${BOARD} board does not use servod. Exiting." >&2
	exit 1
fi

if [[ -z ${SERVOD_PORT} || -z ${SERVO_SERIAL} || -z ${BOARD_NAME} ]]; then
	echo "Missing required variable. Exiting" >&2
	echo " - SERVOD_PORT: ${SERVOD_PORT}" >&2
	echo " - SERVO_SERIAL: ${SERVO_SERIAL}" >&2
	echo " - BOARD_NAME: ${BOARD_NAME}" >&2
	exit 1
fi
HOSTNAME=$(hostname)
CONTAINER_NAME="${HOSTNAME}-docker_servod_${BOARD_NAME}_${SERVOD_PORT}"
LOGFILE="${LOG_DIR}/${BOARD}_servod_${SERVOD_PORT}.log"

if _servod_is_running && [[ -z ${RESTART} ]]; then
	echo "${BOARD} servod is already running - port is ${SERVOD_PORT}." >&2
	exit 0
fi

if [[ "${USE_SERVO_CONTAINER}" -eq 1 ]]; then
	echo "Initializing..."

	if _servod_is_running; then
		echo "Killing existing container..."
		docker kill "${CONTAINER_NAME}"
		sleep 5
	fi

	echo "Starting docker image..."
	start_servod_release.py -h "${HOSTNAME}" -b "${BOARD_NAME}" -m "${BOARD_NAME}" -s "${SERVO_SERIAL}" -p "${SERVOD_PORT}" | \
		tee "${LOGFILE}"

	if ! grep -q "Listening on 0.0.0.0" "${LOGFILE}"; then
		echo "Failed to start servod docker container.  See ${LOGFILE} for information. Exiting." >&2
		exit 1
	fi

elif [[ "${USE_CROS_DIRECTORY}" -eq 1 ]]; then

	cd "${CROS_DIR}" && sudo "${DEPOT_TOOLS_DIR}/cros_sdk" --no-ns-pid -- bash -c "sudo servod --board=${BOARD_NAME} --port=${SERVOD_PORT}  --serial=${SERVO_SERIAL}" | \
		tee "${LOGFILE}"
	sleep 20 
	if ! grep -q "Listening on localhost" "${LOGFILE}"; then
		echo "Failed to start servod docker container.  See ${LOGFILE} for information. Exiting." >&2
		exit 1
	fi
fi

CPU_CONSOLE=$(grep "CPU console on" "${LOGFILE}" | sed 's/.*CPU console on: //')
EC_CONSOLE=$(grep "EC console on" "${LOGFILE}" | sed 's/.*EC console on: //')
GSC_CONSOLE=$(grep "..50 console on" "${LOGFILE}" | sed 's|.*..50 console on: ||')

printf "\nConfiguring /dev links for serial consoles.\n"
sudo rm -f "/dev/${BOARD}_CPU" "/dev/${BOARD}_EC" "/dev/${BOARD}_GSC"
sudo chown user:tty /dev/pts/*
sudo chmod -R g+rw /dev/pts

if [[ -n "${CPU_CONSOLE}" ]]; then sudo ln -f -s "${CPU_CONSOLE}" "/dev/${BOARD}_CPU"; fi
if [[ -n "${EC_CONSOLE}" ]]; then sudo ln -f -s "${EC_CONSOLE}" "/dev/${BOARD}_EC"; fi
if [[ -n "${GSC_CONSOLE}" ]]; then sudo ln -f -s "${GSC_CONSOLE}" "/dev/${BOARD}_GSC"; fi

echo "Servod started successfully."
