#!/usr/bin/env ash
# shellcheck shell=dash

run_cmd() {
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


  if [ -f "${SCRIPT_BASE}/.env" ] || [ -L "${SCRIPT_BASE}/.env" ]; then
    echo "Loading configuration from ${SCRIPT_BASE}/.env..."
    # shellcheck disable=SC1091
    . "${SCRIPT_BASE}/.env"
  elif [ -f "${SCRIPT_BASE}/.env.dist" ] || [ -L "${SCRIPT_BASE}/.env.dist" ]; then
    echo "Loading configuration from ${SCRIPT_BASE}/.env.dist..."
    # shellcheck disable=SC1091
    . "${SCRIPT_BASE}/.env.dist"
  fi
}

# Terminate execution after printing usage help texts
#
# usage(exit_code)
usage() {
  # shellcheck disable=SC2086
  SCRIPT_NAME="$(basename $0)"

  EXIT_CODE="$1"
  if [ -z "$EXIT_CODE" ] || [ "$EXIT_CODE" = "" ]; then
    EXIT_CODE="0"
  fi


  echo "USAGE: This script requires one argument."
  echo "    <hostname>... an IP or hostname to connect to"
  echo "    <command>... is optional and defaults to 'status'"
  echo
  echo "    'on' to trigger the outlet ON."
  echo "    'off' to trigger the outlet OFF."
  echo "    'toggle' to do the inverse of the current power state."
  echo "    'query|status' to perform a status check and then exit."
  echo

  exit $EXIT_CODE
}

load_config

CURL_CMD=$(which curl)
PING_CMD=$(which ping)
PING_ARGS="-4 -w1"
CURL_ARGS="-4"
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
  usage
fi

# Defaults
if [ -z "$PWR_SWITCH_POS" ]; then
  PWR_SWITCH_POS="status"
fi

# Pre-run check
# shellcheck disable=SC2086
if ! run_cmd "${PING_CMD}" ${PING_ARGS} "${HOST}" 1> /dev/null; then
  echo "CRITICAL: The host at ${HOST} appears to be offline. Try again later!"
  echo
  exit 1
fi

#[ -n "$DEBUG" ] && CURL_ARGS="${CURL_ARGS} -v "

# shellcheck disable=SC3036
[ -n "$DEBUG" ] && echo -e "CURL_ARGS: ${CURL_ARGS}\n"

# shellcheck disable=SC3036
[ -n "$DEBUG" ] && echo -e "ARGS: $@\n"

for arg in "$@"; do
  arg=$(echo "$arg" | awk '{print tolower($arg)}')
  case $arg in
    debug|-d|-n)
      CURL_ARGS="${CURL_ARGS} -v"
    ;;
    query|status)
      echo
      # shellcheck disable=SC2086
      # shellcheck disable=SC2086
      # FIXME(jeff): Figure out the correct URL syntax for querying status of device!
      run_cmd "${CURL_CMD}" ${CURL_ARGS} --digest -u ${USERNAME}:${PASSWORD} "http://$HOST/switch/plug0/status" # smart-wifi-plug-1/switch/plug1_relay
      echo
      exit 0
    ;;
    on|turn_on)
      # shellcheck disable=SC2086
      run_cmd "$CURL_CMD" ${CURL_ARGS} --digest -u ${USERNAME}:${PASSWORD} "http://$HOST/switch/relay/turn_on"
    ;;
    off|turn_off)
      # shellcheck disable=SC2086
      run_cmd "$CURL_CMD" ${CURL_ARGS} --digest -u ${USERNAME}:${PASSWORD} "http://${HOST}/switch/relay/turn_off"
    ;;
    toggle)
      # shellcheck disable=SC2086
      # shellcheck disable=SC2091
      if ! $(run_cmd "$CURL_CMD" ${CURL_ARGS} --digest -u ${USERNAME}:${PASSWORD} "http://$HOST/switch/relay/" | grep -i -e "ON"); then
        PWR_SWITCH_POS="turn_off"
      else
        PWR_SWITCH_POS="turn_on"
      fi
    ;;
    h|help)
      usage
    ;;
    *)
      # shellcheck disable=SC2086
      #run_cmd "$CURL_CMD" ${CURL_ARGS} --digest -u ${USERNAME}:${PASSWORD} \
        #"http://${HOST}/switch/relay/${PWR_SWITCH_POS}"
    ;;
  esac
done

exit 0
