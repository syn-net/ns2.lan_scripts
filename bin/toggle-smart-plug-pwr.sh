#!/usr/bin/env ash

run() {
  if [ -n "$DRY_RUN" ]; then
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

load_config

CURL_CMD=$(which curl)
PING_CMD=$(which ping)
PING_ARGS="-4 -w1"
CURL_ARGS="-4"
[ -n "$DEBUG" ] && CURL_ARGS="$CURL_ARGS -v "
HOST="$1"
PWR_SWITCH_POS="$2"

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

[ -n "$DEBUG" ] && echo -e "CURL_ARGS: ${CURL_ARGS}\n"

# First branch
# FIXME(jeff): Figure out the correct URL syntax for querying status of device!
if [ "$PWR_SWITCH_POS" = "query" ] || [ "$PWR_SWITCH_POS" = "status" ]; then
  echo
  # shellcheck disable=SC2086
  run "${CURL_CMD}" ${CURL_ARGS} --digest -u ${USERNAME}:${PASSWORD} "http://$HOST/switch/relay/status"
  echo
  exit 0
fi

# Second and our last branch
if [ "$PWR_SWITCH_POS" = "toggle" ]; then
  # shellcheck disable=SC2086
  # shellcheck disable=SC2091
  if ! $(run "$CURL_CMD" ${CURL_ARGS} --digest -u ${USERNAME}:${PASSWORD} "http://$HOST/switch/relay/" | grep -i -e "ON"); then
    PWR_SWITCH_POS="turn_off"
  else
    PWR_SWITCH_POS="turn_on"
  fi
fi

# shellcheck disable=SC2086
run "$PING_CMD" $PING_ARGS "$HOST" && "$CURL_CMD" ${CURL_ARGS} --digest -u ${USERNAME}:${PASSWORD} \
  "http://${HOST}/switch/relay/${PWR_SWITCH_POS}"

exit 0
