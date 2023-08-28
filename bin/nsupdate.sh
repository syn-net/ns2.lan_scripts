#!/bin/sh
# /root/bin/nsupdate.sh:jeff
#
# Update a subdomain with our current public IP address.
#
# NOTE(jeff): This script is intended to be used with
# crond, although any daemon capable of executing this
# script at a defined time slice ought to work.
#
# FIXME(jeff): Fix the invalid certificate error we get
# when using curl to connect to checkip.mynaughty.party.
# I believe that it is not finding our self-signed
# certificate at startup.
#
# SEE ALSO
# 1. https://ydns.io/api/v1/

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

CURL_ARGS="-k -L --output -"
OUR_IP=$(curl -k -L --output - https://checkip.mynaughty.party)

if [ -z "$YDNS_USERNAME" ] || [ "$YDNS_USERNAME" = "" ]; then
  # shellcheck disable=SC3037
  echo -e "The YDNS_USERNAME environment variable is missing. Consult '.env.dist' for more information.\n"
  exit 255
fi

if [ -z "$YDNS_PASSWORD" ] || [ "$YDNS_PASSWORD" = "" ]; then
  # shellcheck disable=SC3037
  echo -e "The YDNS_PASSWORD environment variable is missing. Consult '.env.dist' for more information.\n"
  exit 255
fi

if [ -z "$YDNS_HOST" ] || [ "$YDNS_HOST" = "" ]; then
  # shellcheck disable=SC3037
  echo -e "The YDNS_HOST environment variable is missing. Consult '.env.dist' for more information.\n"
  exit 255
fi

if [ -z "$YDNS_UPDATE_URL" ] || [ "$YDNS_UPDATE_URL" = "" ]; then
  # shellcheck disable=SC3037
  echo -e "The YDNS_UPDATE_URL environment variable is missing. Consult '.env.dist' for more information.\n"
  exit 255
fi

if [ -n "$1" ]; then
  OUR_IP="$1"
fi

if [ "$OUR_IP" = "" ]; then
  # shellcheck disable=SC3037
  echo -e "Unable to detect your public IP address. Exiting...\n"
  exit 255
fi

echo -e "Updating ${YDNS_HOST} with ${OUR_IP} at ${YDNS_UPDATE_URL}...\n"

# shellcheck disable=SC2086
curl $CURL_ARGS --user "${YDNS_USERNAME}:${YDNS_PASSWORD}" "${YDNS_UPDATE_URL}/?host=${YDNS_HOST}&ip=${OUR_IP}"
