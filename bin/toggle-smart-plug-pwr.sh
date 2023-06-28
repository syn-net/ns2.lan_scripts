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

load_config() {
  # shellcheck disable=SC2086
  SCRIPT_BASE="$(dirname $0)"

  if [ -f "${SCRIPT_BASE}/.env.development" ] || [ -L "${SCRIPT_BASE}/.env.development" ]; then
    echo "Loading configuration from ${SCRIPT_BASE}/.env.development..."
    # shellcheck disable=SC1091
    . "${SCRIPT_BASE}/.env.development"
  elif [ -f "${SCRIPT_BASE}/.env" ] || [ -L "${SCRIPT_BASE}/.env" ]; then
    echo "Loading configuration from ${SCRIPT_BASE}/.env..."
    # shellcheck disable=SC1091
    . "${SCRIPT_BASE}/.env"
  else
    echo "Loading configuration from ${SCRIPT_BASE}/.env.dist..."
    # shellcheck disable=SC1091
    . "${SCRIPT_BASE}/.env.dist"
  fi
}

CURL_CMD=$(which curl)
PING_CMD=$(which ping)
PING_ARGS="-4 -w1"
CURL_ARGS="-4"
HOST="$1"
PWR_SWITCH_POS="$2"

load_config

# Pre-run sanity check
if [ ! -x "$CURL_CMD" ]; then
  echo "CRITICAL: Could not find curl at ${CURL_CMD}."
  echo
  exit 2
fi

# Pre-run sanity check
if [ ! -x "$PING_CMD" ]; then
  echo "CRITICAL: Could not find ping at ${PING_CMD}."
  echo
  exit 2
fi

# obligatory usage text
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

# Defaults
if [ -z "$PWR_SWITCH_POS" ]; then
  PWR_SWITCH_POS="query"
fi

# Pre-run check
# shellcheck disable=SC2086
if ! run "${PING_CMD}" ${PING_ARGS} "${HOST}" > /dev/null; then
  echo "CRITICAL: The host at ${HOST} appears to be offline. Try again later!"
  echo
  exit 1
fi

# First branch
if [ "$PWR_SWITCH_POS" = "query" ]; then
  echo
  # shellcheck disable=SC2086
  "${CURL_CMD}" "${CURL_ARGS}" \
    "http://$HOST/cm?cmnd=Power&user=${USERNAME}&password=${PASSWORD}"
  echo
  exit 0
fi

# Second and our last branch
if [ "$PWR_SWITCH_POS" = "toggle" ]; then
  # shellcheck disable=SC2086
  # shellcheck disable=SC2091
  if ! $(run "$CURL_CMD" "$CURL_ARGS" "http://$HOST/cm?cmnd=Power&user=${USERNAME}&password=${PASSWORD}" | grep -i -e "ON"); then
    PWR_SWITCH_POS="OFF"
  else
    PWR_SWITCH_POS="ON"
  fi
fi

# shellcheck disable=SC2086
run "$PING_CMD" $PING_ARGS "$HOST" && "$CURL_CMD" "$CURL_ARGS" \
  "http://${HOST}/cm?cmnd=Power%20${PWR_SWITCH_POS}&user=${USERNAME}&password=${PASSWORD}"

exit 0
