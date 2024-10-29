#!/usr/bin/bash
# SPDX-License-Identifier: MIT

source "${WORKDIR}/_board_helpers.sh" || exit 1

TIME="$(tail "${CMDLIST}" -n 1 | sed 's|+0000.*|+0000|')"
USR_CMD="$(tail "${CMDLIST}" -n 1 | sed 's|i.*+0000||')"

echo "Last command: ${USER_CMD} $(timeago.sh "${TIME}")"

