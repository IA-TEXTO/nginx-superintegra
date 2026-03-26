#!/usr/bin/env bash
set -euo pipefail

if [ ! -f ".env" ]; then
  echo "Arquivo .env não encontrado."
  echo "Copie .env.example para .env e ajuste os valores."
  exit 1
fi

set -a
source .env
set +a

echo "Emitindo certificado para ${CHATBOT_INTEGRACAR_DOMAIN} e ${CHATBOT_INTEGRACAR_WWW_DOMAIN}..."
docker compose run --rm certbot certonly \
  --webroot \
  -w /var/www/certbot \
  --email "${LETSENCRYPT_EMAIL}" \
  --agree-tos \
  --no-eff-email \
  -d "${CHATBOT_INTEGRACAR_DOMAIN}" \
  -d "${CHATBOT_INTEGRACAR_WWW_DOMAIN}"

echo "Emitindo certificado para ${WORKSTATIONS_COLATINA_DOMAIN}..."
docker compose run --rm certbot certonly \
  --webroot \
  -w /var/www/certbot \
  --email "${LETSENCRYPT_EMAIL}" \
  --agree-tos \
  --no-eff-email \
  -d "${WORKSTATIONS_COLATINA_DOMAIN}"

echo "Emitindo certificado para ${FILES_DOMAIN}..."
docker compose run --rm certbot certonly \
  --webroot \
  -w /var/www/certbot \
  --email "${LETSENCRYPT_EMAIL}" \
  --agree-tos \
  --no-eff-email \
  -d "${FILES_DOMAIN}"

docker compose exec nginx sh -c 'touch /var/www/certbot/.reload-nginx'

echo "Concluído."