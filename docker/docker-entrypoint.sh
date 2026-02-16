#!/bin/sh
set -e

# Default JELLYFIN_URL to empty if not set
export JELLYFIN_URL="${JELLYFIN_URL:-}"

# Process nginx config template with environment variables
envsubst '${JELLYFIN_URL}' < /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf

echo "Starting Finar web server..."
echo "JELLYFIN_URL: ${JELLYFIN_URL:-'(not set - direct connection mode)'}"

exec "$@"
