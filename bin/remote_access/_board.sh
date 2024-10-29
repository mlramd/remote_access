#!/usr/bin/bash
# SPDX-License-Identifier: MIT

if mount | grep "on / " | grep -q "ro"; then
	sudo rw >/dev/null 2>&1
fi

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
export WORKDIR="${SCRIPT_DIR}/remote_access"

source "${WORKDIR}/_board_helpers.sh" || exit 1

CMD="$(echo "$1" | tr '_' '-')"
shift

if [[ -f "${RESERVATION_FILE}" && "${CMD}" != "release" ]]; then
	if ! "${WORKDIR}/_board_reserve_release.sh" status; then
		exit 1
	fi
fi

if [[ -x "${WORKDIR}/${BOARD}-${CMD}" ]]; then

  if [[ "${CMD}" != "last-cmd" ]]; then
		"${WORKDIR}/_update_time.sh" "${BOARD}" "${CMD}" "$*"
	fi

	"${WORKDIR}/${BOARD}-${CMD}" "$@"
	exit $?
fi
if [[ -n "${CMD}" && ! "${CMD}" = "-h" && ! "${CMD}" = "--help" ]]; then
	echo "Error: ${CMD} is not valid for ${BOARD}." >&2
fi

echo "Usage: ${BOARD} <command>"
echo " Valid commands for ${BOARD}:"
find "${WORKDIR}" -name "${BOARD}-*" | sed "s/.*${BOARD}-/  - /" | sort
exit 1
