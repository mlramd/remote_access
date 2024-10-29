#!/usr/bin/bash
# SPDX-License-Identifier: MIT

source "${WORKDIR}/_board_helpers.sh" || exit 1

USER=root

run_ssh_cmd() {
	IP=$1

	if [[ -z "${IP}" ]]; then
		echo "Error: IP address is not set."
		return 1
	elif ! ping "${IP}" -c 1; then
		echo "Error: Could not ping IP address ${IP}"
		return 1
	fi

	if [[ -n "${SSH_KEY}" ]]; then
		ssh -i "${SSH_KEY}" "${USER}@${IP}"
	else 
		ssh "${USER}@${IP}"
	fi
	return $?
}


if [[ -z "${IP_ADDRESS}" && -z "${WIFI_IP}" ]]; then
	echo "Error: Neither IP_ADDRESS nor WIFI_IP is set. Exiting." >&2
	exit 1
fi

echo "SSHing to wired IP: ${IP_ADDRESS}"
if ! run_ssh_cmd "${IP_ADDRESS}"; then
	echo "SSHing to WIFI IP: ${WIFI_IP}"
	run_ssh_cmd "${WIFI_IP}"
fi


