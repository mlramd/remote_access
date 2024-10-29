#!/usr/bin/bash
# SPDX-License-Identifier: MIT

set -e

# Number of 30 second intervals with no change before turning off the board
#DELAYCOUNT=10
#UPDATE_TIME=0

source "${WORKDIR}/_board_helpers.sh" || exit 1

look_for_rom() {
  ROM="$(find "${INCOMING_ROM_DIR}" \( -iname "*.rom" -o -iname "*.bin" \) | head -n 1)"
}

#kill_log() {
#    if [[ -n "${LOG_PID}" ]]; then
#       kill -0 "${LOG_PID}" >/dev/null 2>&1 ; sleep 1 ; kill -9 "${LOG_PID}" || true
#       kill -0 "${TAIL_PID}" >/dev/null 2>&1 ; sleep 1 ; kill -9 "${TAIL_PID}" || true
#    fi
#}

wait_for_rom() {
  mkdir -p "${INCOMING_ROM_DIR}"
  # Wait for a new rom - Turn off board after a while.
  if [[ -z "${ROM}" || ! -f "${ROM}" ]]; then
	sleep 30
	
#	if [[ "${RUNNING}" -eq 0 ]]; then
#		printf "."
#		return 0
#	fi
#
#	CMDLIST_SHA="$(sha256sum "${CMDLIST}")"
#	LOGFILE_SHA="$(sha256sum "${LOGFILE}")"
#	if [[ "${LOGFILE_SHA}" != "${OLD_LOGFILE_SHA}" || "${CMDLIST_SHA}" != "${OLD_CMDLIST_SHA}" ]]; then
#		OLD_LOGFILE_SHA="${LOGFILE_SHA}"
#		OLD_CMDLIST_SHA="${CMDLIST_SHA}"
#		UPDATE_TIME=0
#	else
#		(( UPDATE_TIME++ ))
#	fi
#	if [[ "${UPDATE_TIME}" = "${DELAYCOUNT}" ]]; then
#		echo "Run seems to be done.  Powering off board and closing log."
#		kill_log
#		"${BOARD}" "off" "# Testscript"
#		RUNNING=0
#		#reset
#		echo "waiting for a rom file in ${INCOMING_ROM_DIR}..."
#	fi
#	return 0
  else
	return 1
  fi
}

# RUNNING=0
echo "waiting for a rom file in ${INCOMING_ROM_DIR}..."
while true; do
  look_for_rom
  if wait_for_rom; then
	  continue
  fi
  ROMTIME="$(date -Iseconds)"
  ROMFILE="$(basename "${ROM}")"
  echo "New ROM arrived: ${ROM}"

    #if [[ "${RUNNING}" -ne 0 ]]; then
	#kill_log
    #fi
    # Prepare the board
    echo "Turn on power to the board, and make sure it's off"
    "${BOARD}" "power-on" "# Testscript"
    "${BOARD}" "off" "# Testscript"

    # Flash the firmware
    echo "Flashing ${ROM}"
    if ! "${BOARD}" "flash" "${ROM}" "# Testscript"; then
	    echo "Error: Flash failed. Retrying."
	    continue
    else
	    echo "Board flashed successfully."
    fi

    #check_group "tty"
    #mkdir -p "${LOG_DIR}"
    #LOGFILE="${LOG_DIR}/seriallog-${ROMTIME}.log"
    #touch "${LOGFILE}"
    #check_for_cmd "grabserial"
    #nohup grabserial --quiet --skip --device="/dev/${BOARD}_CPU" --systime --baudrate="115200" --output="${LOGFILE}" & 
    #LOG_PID="$(pgrep -a grabserial | grep "${LOGFILE}" | cut -f1 -d' ')"
    #echo "Saving log to ${LOGFILE} - PID: ${LOG_PID}"
    #tail -f "${LOGFILE}" &
    #TAIL_PID="$!"

    sleep 2
    "${BOARD}" "on" "# Testscript"

    mkdir -p "${ARCHIVE_ROM_DIR}"
    mv -f "${ROM}" "${ARCHIVE_ROM_DIR}/${ROMTIME}_${ROMFILE}"

#    OLD_LOGFILE_SHA=0
#    RUNNING=1
done
