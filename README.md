# Reverse Proxy principal com Nginx + Certbot

Este projeto sobe o Nginx principal do servidor e centraliza:

- roteamento público por domínio
- HTTPS com Let's Encrypt
- redirecionamento HTTP -> HTTPS
- proxy reverso para múltiplos apps Django
- exposição pública de PDFs com autenticação básica

## Arquitetura

Fluxo:

Internet -> Nginx principal -> app interno correspondente

Exemplo:

- chatbotintegracar.online -> app1_nginx:80
- app2.chatbotintegracar.online -> app2_nginx:80
- arquivos.chatbotintegracar.online -> PDFs locais do host

## Pré-requisitos

- Docker e Docker Compose instalados
- DNS dos domínios apontando para o IP público do servidor
- portas 80 e 443 liberadas no firewall/roteador
- rede Docker externa `proxy` criada
- stacks internas dos apps conectadas à rede `proxy`

## Importante sobre os apps internos

Os apps internos não devem mais ser a borda pública.

O Nginx interno de cada app deve ficar responsável apenas por:
- static
- media
- proxy para Gunicorn/Uvicorn/Django
- client_max_body_size
- timeouts específicos do app

O que deve sair dos apps internos:
- listen 443 ssl
- certificados Let's Encrypt
- location `/.well-known/acme-challenge/`
- redirect HTTP -> HTTPS público
- papel de "servidor final da internet"

## 1. Criar a rede externa

```bash
docker network create proxy
```