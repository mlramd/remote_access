#!/usr/bin/bash
# SPDX-License-Identifier: MIT

source "${WORKDIR}/_board_helpers.sh" || exit 1

UART="$(basename "$0" | sed "s/.*${BOARD}-//; s/-.*//")"
_get_pty "${UART}"

check_for_cmd "minicom"
check_group "tty"

sudo minicom -D "${PTY}"
