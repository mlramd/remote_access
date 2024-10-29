#!/usr/bin/bash
# SPDX-License-Identifier: MIT

SLEEP_TIME=1
FLASHROM_VERIFY="-n" # Default to no verification
RETCODE=0

# Get the capture type from the script name
FLASHTYPE="$(basename "$0" | sed "s/.*${BOARD}-flash-//")"

echo "flashtype: ${FLASHTYPE} Basename $(basename "$0")"

if [[ -z "${WORKDIR}" ]]; then
	WORKDIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
fi
source "${WORKDIR}/_board_helpers.sh" || exit 1

if [[ "${FLASHTYPE}" = "known-good" ]]; then
	if [[ -z "${KNOWN_GOOD_ROM}" ]]; then
		echo "Error: Known good ROM not set. Exiting."
		exit 1
	fi
	ROM="${KNOWN_GOOD_ROM}"
	ROMFILE="$(basename "${ROM}")"
else
	ROM=$1
	ROMFILE="$(basename "${ROM}")"
fi

if [[ ! -f "${ROM}" ]]; then
	echo "Error: Could not find ${ROM}. Exiting." >&2
	exit 1
fi

# Dediprog
if [[ "${USE_DEDIPROG}" -eq 1 ]]; then
	if [[ -z ${DEDIPROG_SERIAL} ]]; then
		echo "Missing required DEDIPROG_SERIAL variable. Exiting" >&2
		exit 1
	elif [[ -z "${DEDIPROG_VOLTAGE}" ]]; then
		echo "Error: Missing required DEDIPROG_VOLTAGE variable. Exiting." >&2
		exit 1
	elif [[ -z "${DEDIPROG_SPEED}" ]]; then
		echo "Error: Missing required DEDIPROG_SPEED variable. Exiting." >&2
		exit 1
	fi

	# Check whether we're using flashrom and make sure it's installed
	if [[ "${USE_FLASHROM}" -eq 1 && -z "$(command -v flashrom)" ]]; then
		echo "Error: Flashrom is not installed."
		echo "See https://flashrom.org/"
		echo "Exiting."
		exit 1
	fi

	# dpcmd is required for either dpcmd or flashrom, so must be installed
	if [[ -z "$(command -v dpcmd)" ]] || ! dpcmd --help >/dev/null 2>&1; then
		echo "Error: dpcmd is not installed."
		echo "See https://github.com/DediProgSW/SF100Linux"
		echo "Exiting."
		exit 1
	fi

	DEVICE="$(sudo dpcmd --list-device-id 0 | grep "${DEDIPROG_SERIAL}" | cut -f 1 -d ',')"
	if [[ -z "${DEVICE}" ]]; then
		echo "Error: Could not find device with serial number ${DEDIPROG_SERIAL}. Exiting."
		exit 1
	fi

	echo "Flashing ${ROM}"
	if [[ "${USE_FLASHROM}" -eq 1 ]]; then
		sudo flashrom -p "dediprog:voltage=${DEDIPROG_VOLTAGE},spispeed=${DEDIPROG_SPEED},device=${DEVICE}" -w "${ROM}" -v
	else
		dpcmd --vcc "${DEDIPROG_VOLTAGE}" --auto "${ROM}" --spi-clk "${DEDIPROG_SPEED}" --verify --device "${DEVICE}"
	fi
	RETCODE=$?

	if [[ "${USE_USB_RELAY}" -eq 1 && -n "${USB_RELAY_RESET_DEDIPROG}" ]]; then
		echo "Resetting Dediprog"
		"${WORKDIR}/_usb_relay_control.sh" "${BOARD}" RESET_DEDIPROG "toggle"
	fi

# Servo
elif [[ "${FLASH_WITH_SERVO}" -eq 1 ]]; then

	if [[ -z "$(command -v flashrom)" ]] || ! flashrom --help >/dev/null 2>&1; then
		echo "Error: flashrom is not installed."
		echo "See https://www.flashrom.org/Flashrom"
		echo "Exiting."
		exit 1
	fi

	if [[ -n "${DEBUG}" ]]; then
		VERBOSE="-VVV"
	fi

	if [ -n "${PRE_FLASH_CMD}" ]; then
		"${WORKDIR}/_dut_control.sh" "${BOARD}" "${PRE_FLASH_CMD}" || exit 1
	fi

	sleep "${SLEEP_TIME}"

	if [[ "${USE_FLASHROM}" -eq 1 ]]; then
		sudo flashrom -p "raiden_debug_spi:serial=${SERVO_SERIAL}" -E -i RW_MRC_CACHE -N ${FLASHROM_VERIFY} ${VERBOSE}
		sudo flashrom -p "raiden_debug_spi:serial=${SERVO_SERIAL}" -w "${ROM}" ${FLASHROM_VERIFY} ${VERBOSE}
		RETCODE=$?

	elif [[ "${USE_SERVO_CONTAINER}" -eq 1 ]]; then
		check_group "sudo"
		HOSTNAME=$(hostname)
		CONTAINER_NAME="${HOSTNAME}-docker_servod_${BOARD_NAME}_${SERVOD_PORT}"
		cp "${ROM}" "/dev/_${ROMFILE}"
		#docker exec "${CONTAINER_NAME}" flashrom -p "raiden_debug_spi:serial=${SERVO_SERIAL}" -E -i RW_MRC_CACHE -N ${FLASHROM_VERIFY} ${verbose}
		sleep 1
		docker exec "${CONTAINER_NAME}" futility update --image="/dev/_${ROMFILE}" --mode=factory --force --servo_port="${SERVOD_PORT}"
		RETCODE=$?
		rm -f "/dev/_${ROMFILE}"
	else
		cp "${ROM}" "${CROS_DIR}/chroot/tmp/_${ROMNAME}"
		cd "${CROS_DIR}" && "${DEPOT_TOOLS_DIR}/cros_sdk" --no-ns-pid -- bash -c "cros ap flash /tmp/_${ROMNAME}"
		rm -f "${CROS_DIR}/chroot/tmp/_${ROMNAME}"
	fi

	if [ -n "${POST_FLASH_CMD}" ]; then
		"${WORKDIR}/_dut_control.sh" "${BOARD}" "${POST_FLASH_CMD}"
	fi
fi

exit "${RETCODE}"
