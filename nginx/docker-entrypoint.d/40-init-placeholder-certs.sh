#!/bin/sh
set -eu

create_cert() {
  domain="$1"

  if [ -z "$domain" ]; then
    return 0
  fi

  live_dir="/etc/letsencrypt/live/$domain"

  if [ ! -f "$live_dir/fullchain.pem" ] || [ ! -f "$live_dir/privkey.pem" ]; then
    echo "[init-certs] Criando certificado temporário para $domain"
    mkdir -p "$live_dir"

    openssl req -x509 -nodes -newkey rsa:2048 -days 1 \
      -keyout "$live_dir/privkey.pem" \
      -out "$live_dir/fullchain.pem" \
      -subj "/CN=$domain"
  fi
}

create_cert "${CHATBOT_INTEGRACAR_DOMAIN:-}"
create_cert "${WORKSTATIONS_COLATINA_DOMAIN:-}"
create_cert "${FILES_DOMAIN:-}"