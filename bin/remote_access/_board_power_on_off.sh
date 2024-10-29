#!/usr/bin/bash
# SPDX-License-Identifier: MIT

source "${WORKDIR}/_board_helpers.sh" || exit 1

POWER_STATE="$(echo "$0" | grep -- "-power-" | sed 's/.*-//')"

if [[ -n "${USE_WEBPOWER}" ]]; then
	"${WORKDIR}/_webpower.sh" "${BOARD}" "${POWER_STATE}"
else
	echo "Unknown power control method. Exiting." >&2
	exit 1
fi
