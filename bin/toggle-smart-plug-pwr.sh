#!/usr/bin/env ash

#NOM_DEBUG=1

run() {
  if [ -n "$NOM_DEBUG" ]; then
    # shellcheck disable=SC2145
    echo "DEBUG: $@"
  else
    "$@"
  fi
}

CURL_CMD=$(command -v curl)
PING_CMD=$(command -v ping)
PING_ARGS="-4 -w1"
CURL_ARGS="-4"
HOST=$1
PWR_SWITCH_POS=$2

if [ -z "$HOST" ]; then
  echo "USAGE: This script requires one argument."
  echo "    <hostname>... an IP or hostname to connect to"
  echo "    <command>... is optional and defaults to 'query'"
  echo
  echo "    'on' to trigger the outlet ON."
  echo "    'off' to trigger the outlet OFF."
  echo "    'toggle' to do the inverse of the current power state."
  echo "    'query' to perform a status check and then exit."
  echo
  exit 255
fi

if [ -z "$PWR_SWITCH_POS" ]; then
  PWR_SWITCH_POS="query"
fi

if [ "$PWR_SWITCH_POS" = "query" ]; then
  echo
  # shellcheck disable=SC2086
  run "$PING_CMD" $PING_ARGS "$HOST" && "$CURL_CMD" "$CURL_ARGS" \
    "http://$HOST/cm?cmnd=Power&user=admin&password=19841985"
  echo
  exit 0
fi


if [ "$PWR_SWITCH_POS" = "toggle" ]; then
  # shellcheck disable=SC2086
  # shellcheck disable=SC2091
  if ! $(run "$PING_CMD" $PING_ARGS "$HOST" && "$CURL_CMD" "$CURL_ARGS" "http://$HOST/cm?cmnd=Power&user=admin&password=19841985" | grep -i -e "ON"); then
    PWR_SWITCH_POS="OFF"
  else
    PWR_SWITCH_POS="ON"
  fi
fi

if [ ! -x "$CURL_CMD" ]; then
  echo "CRITICAL: Could not find curl at ${CURL_CMD}."
  echo
  exit 2
fi

if [ ! -x "$PING_CMD" ]; then
  echo "CRITICAL: Could not find ping at ${PING_CMD}."
  echo
  exit 2
fi

# shellcheck disable=SC2086
run "$PING_CMD" $PING_ARGS "$HOST" && "$CURL_CMD" "$CURL_ARGS" "http://$HOST/cm?cmnd=Power%20${PWR_SWITCH_POS}&user=admin&password=19841985"

exit 0
