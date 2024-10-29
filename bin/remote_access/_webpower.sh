#!/usr/bin/bash
# SPDX-License-Identifier: MIT

BOARD=$1
POWER_STATE=$2

source "${WORKDIR}/_board_helpers.sh" || exit 1

if [[ -z "${BOARD}" ]]; then
	echo "Board name must be specified. Exiting." >&2
	exit 1
fi

if [[ "${POWER_STATE,,}" != "on" && "${POWER_STATE,,}" != "off" && "${POWER_STATE,,}" != "status" ]]; then
	echo "Power state must be either 'on' or 'off'. Exiting." >&2
	exit 1
fi

if [[ -z "${USE_WEBPOWER}" ]]; then
	echo "${BOARD} board does not use webpower switch. Exiting." >&2
	exit 1
fi

if [[ -z ${POWER_OUTLET_NUM} || -z ${WEBPOWER_HOST} ]]; then
	echo "Missing required variable. Exiting" >&2
	echo " - POWER_OUTLET_NUM: ${POWER_OUTLET_NUM}" >&2
	echo " - WEBPOWER_HOST: ${WEBPOWER_HOST}" >&2
	exit 1
fi

if ! ping "${WEBPOWER_HOST}" -c 1 >/dev/null 2>&1; then
	echo "Error: Could not connect to webpower switch." >&2
	echo "       Check the network connection. Exiting." >&2
	exit 1
fi

if [[ "${POWER_STATE,,}" != "status" ]]; then
	curl -k "https://${WEBPOWER_USERNAME}:${WEBPOWER_PASSWORD}@${WEBPOWER_HOST}/outlet?${POWER_OUTLET_NUM}=${POWER_STATE^^}" >/dev/null 2>&1
fi

sleep 1

WEBPOWER_STATUS="0x$(curl -k -u "${WEBPOWER_USERNAME}:${WEBPOWER_PASSWORD}" "http://${WEBPOWER_HOST}/status" 2>/dev/null | grep 'id="state"' | sed 's/.*">//; s/<.*//')"
POWER_STATUS="$((WEBPOWER_STATUS & (1 << (POWER_OUTLET_NUM - 1))))"
if [[ "${POWER_STATUS}" = "0" ]]; then
	echo "Wall Power is off."
else
	echo "Wall Power is on."
fi

#echo "Power Status: ${POWER_STATUS}"
#echo "Webpower Status: ${WEBPOWER_STATUS}"
#echo "Power State: ${POWER_STATE}"
#echo "Board: ${BOARD}"
#echo "Webpower Host: ${WEBPOWER_HOST}"
