#!/usr/bin/bash
# SPDX-License-Identifier: MIT

source "${WORKDIR}/_board_helpers.sh" || exit 1

usage() {
	if [[ "${RESERVATION_STATE,,}" = "reserve" ]]; then
		echo "Usage: $(basename "$0") <minutes> [username]"
		echo "       Maximum reservation time: ${MAX_RESERVATION_MINUTES} minutes."
	else
		echo "Usage: $(basename "$0") [username]"
	fi
	exit 0
}

show_status() {
	check_reservation_file
	if [[ "${RESERVED_UNTIL}" -ge "${NOW}" && "${USERNAME}" != "${RESERVED_BY}" ]]; then
	  echo "Username: $(USERNAME)"
		echo "Notice: The ${BOARD} board is reserved by ${RESERVED_BY} until $(date -d "@${RESERVED_UNTIL}" -Ru)." >&2
		echo "        That's $(((RESERVED_UNTIL - NOW) / 60)) minutes from now." >&2
		echo "        If you need it sooner, please reach out to them to release it." >&2
		echo "        You can also release the board by running release as their username if needed." >&2
		exit 1
	elif [[ "${USERNAME}" = "${RESERVED_BY}" ]]; then
		echo "${BOARD} reserved for $(((RESERVED_UNTIL - NOW) / 60)) minutes." >&2
		exit 0
	fi
}

check_reservation_file() {
	if [[ -f "${RESERVATION_FILE}" ]]; then
		RESERVED_UNTIL="$(head -n1 "${RESERVATION_FILE}")"
		RESERVED_BY="$(tail -n1 "${RESERVATION_FILE}")"
	fi
}

if [[ "$1" = "-h" || "$1" = "--help" ]]; then
	usage
fi

RESERVATION_STATE="$(echo "$0" | grep "${BOARD}-" | sed 's/.*-//')"
NOW="$(date +"%s")"

if [[ -n "$USERNAME" ]]; then
	"${WORKDIR}/set_user.sh" "${USERNAME}"
else
	USERNAME="$("${WORKDIR}/set_user.sh")"
fi

if [[ -z "${USERNAME}" ]]; then
	USERNAME=${USER}
fi

if [[ "$1" = "status" ]]; then
	show_status
	exit 0
fi

RESERVATION_MINUTES="$(printf "%d" "$1")"

if [[ "${RESERVATION_STATE,,}" = "reserve" ]]; then
	if [[ -z "${RESERVATION_MINUTES}" || "${RESERVATION_MINUTES}" -le 0 ]]; then
		usage
	elif [[ "${RESERVATION_MINUTES}" -gt "${MAX_RESERVATION_MINUTES}" ]]; then
		usage
	fi
	USERNAME="$2"
elif [[ "${RESERVATION_STATE,,}" = "release" ]]; then
	USERNAME="$1"
else
	show_status
	echo "Error: Unknown reservation state '${RESERVATION_STATE}'. Exiting." >&2
	exit 1
fi

show_status

if [[ "${RESERVATION_STATE,,}" = "reserve" ]]; then
	RESERVATION_END="$((NOW + (RESERVATION_MINUTES * 60)))"
	echo "${RESERVATION_END}" >"${RESERVATION_FILE}"
	echo "${USERNAME}" >>"${RESERVATION_FILE}"
	echo "Time is now $(date -d "@${NOW}" -Ru) - reserving for ${RESERVATION_MINUTES} minutes for ${USERNAME}."
	echo "${BOARD} marked as reserved until $(date -d "@${RESERVATION_END}" -Ru)."
elif [[ "${RESERVATION_STATE,,}" = "release" ]]; then
	rm -rf "${RESERVATION_FILE}"
	echo "${BOARD} resevation removed."
fi
