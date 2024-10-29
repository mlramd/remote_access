#!/usr/bin/bash
# SPDX-License-Identifier: MIT

source "${WORKDIR}/_board_helpers.sh" || exit 1

UART="$(basename "$0" | sed "s/.*${BOARD}-//; s/-.*//")"
_get_pty "${UART}"

LOG_FILE="${BOARD}_${UART}_$(date -Iseconds)"

check_for_cmd "picocom"
check_group "tty"


if [[ "${UART}" = "cpu" && ! "${USE_SERVOD}" -eq 1 ]] || ! "${WORKDIR}/_dut_control.sh" "${BOARD}" cpu_uart_timestamp:on; then
	picocom "${PTY}" --escape a --nolock --baud 115200 | ts -s "%H:%M:%.S" | tee "${LOG_DIR}/${LOG_FILE}"
else
	picocom "${PTY}" --escape a --nolock --baud 115200 | tee "${LOG_DIR}/${LOG_FILE}"
fi
