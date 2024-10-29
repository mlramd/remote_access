#!/usr/bin/env bash

SEC_PER_MINUTE=$((60))
SEC_PER_HOUR=$((60 * 60))
SEC_PER_DAY=$((60 * 60 * 24))
SEC_PER_MONTH=$((60 * 60 * 24 * 30))
SEC_PER_YEAR=$((60 * 60 * 24 * 365))

last_unix="$(date --date="$1" +%s)" # convert date to unix timestamp
now_unix="$(date +'%s')"

delta_s=$((now_unix - last_unix))

if ((delta_s < SEC_PER_MINUTE * 2)); then
  echo $((delta_s))" seconds ago"
elif ((delta_s < SEC_PER_HOUR * 2)); then
  echo $((delta_s / SEC_PER_MINUTE))" minutes ago"
elif ((delta_s < SEC_PER_DAY * 2)); then
  echo $((delta_s / SEC_PER_HOUR))" hours ago"
elif ((delta_s < SEC_PER_MONTH * 2)); then
  echo $((delta_s / SEC_PER_DAY))" days ago"
elif ((delta_s < SEC_PER_YEAR * 2)); then
  echo $((delta_s / SEC_PER_MONTH))" months ago"
else
  echo $((delta_s / SEC_PER_YEAR))" years ago"
fi
