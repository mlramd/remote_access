#!/usr/bin/bash
# SPDX-License-Identifier: MIT

export BOARD=$1
shift

source "${WORKDIR}/_board_helpers.sh" || exit 1

mkdir -p "$(dirname "${CMDLIST}")"

CMD_DATE="$(date -R)"
echo "${CMD_DATE} ${USER} $*" >> "${CMDLIST}"

