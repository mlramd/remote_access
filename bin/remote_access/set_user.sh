#!/usr/bin/bash
# SPDX-License-Identifier: MIT

source "${WORKDIR}/_board_helpers.sh" || exit 1

active_user=$1
active_ttys=$(who | tr -s ' ' ' ' | cut -f2 -d' ' | tr '/' '_')
current_tty=$(tty | sed 's|/dev/||' | tr '/' '_')

# Remove inactive PTS files
while IFS= read -r -d '' pts
do
	pts="$(echo "${pts}" | sed 's|/tmp/||;s|_user||')"
	if ! grep -q "${pts}" <<< "${active_ttys}"; then
		echo "removing ${pts}_user - logged out."
		rm -f "/tmp/${pts}_user"
	fi
done < <(find /tmp -maxdepth 1 -name "pts_*_user" -print0)

if [ -n "${active_user}" ]; then
  echo "${active_user}" > "/tmp/${current_tty}_user"
elif [[ -f "/tmp/${current_tty}_user" ]]; then
  cat "/tmp/${current_tty}_user"
else
	exit 1
fi
