#!/bin/sh
set -eu

(
  while :; do
    if [ -f /var/www/certbot/.reload-nginx ]; then
      echo "[nginx] Sinal de reload detectado"
      rm -f /var/www/certbot/.reload-nginx
      nginx -s reload || true
    fi
    sleep 30
  done
) &