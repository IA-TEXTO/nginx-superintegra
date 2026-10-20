# nginx-superintegra

Proxy HTTPS dos serviços na rede Docker externa `proxy`. Cada template em
`nginx/templates/` usa os domínios e upstreams do `.env`.

## traçô em traco.run

O template `nginx/templates/traco.conf.template` encaminha `traco.run` para
`traco:8000`, redirecionando HTTP para HTTPS. O aplicativo precisa executar no
mesmo servidor e participar da rede `proxy`; o Compose do repositório `traçô`
já configura essa conexão. Prepare e inicie o aplicativo conforme o README dele.

As variáveis adicionadas ao `.env` são:

```dotenv
TRACO_DOMAIN=traco.run
TRACO_UPSTREAM=traco:8000
```

### Certificado e Cloudflare

1. Na zona `traco.run` da Cloudflare, crie um registro DNS **A**, nome `@`, com
   o IP público do servidor e **Proxy ativado** (nuvem laranja). Se usar IPv6,
   publique AAAA somente se esse mesmo servidor atender por IPv6.
2. Em **SSL/TLS → Origin Server**, emita um certificado **Origin CA** que inclua
   `traco.run`. Instale o certificado e a chave privada neste servidor como:

   ```text
   nginx/certs/traco-origin.crt
   nginx/certs/traco-origin.key
   ```

   Esses arquivos são ignorados pelo Git. Restrinja o acesso à chave privada
   (`chmod 600 nginx/certs/traco-origin.key`). O novo template usa arquivos
   próprios: os certificados `origin.crt` e `origin.key` dos outros serviços
   continuam em seus caminhos atuais.
3. Em **SSL/TLS → Overview**, selecione **Full (strict)**. As portas 80 e 443
   precisam chegar ao Nginx. Esse fluxo exige HTTPS entre Cloudflare e origem;
   o modo Flexible provoca redirecionamentos repetidos.
4. No aplicativo Strava, defina o domínio de callback como `traco.run` e use
   `https://traco.run/accounts/strava/login/callback/` como callback completo.

Não publique o novo template sem instalar o certificado e a chave: o Nginx
recusa iniciar se qualquer certificado configurado estiver ausente. O fluxo de
deploy por push na branch `main` é automático; prepare os arquivos no servidor
**antes** de enviar essa alteração. O workflow valida a configuração em um
container temporário antes de recriar o proxy; se faltar o certificado, o deploy
é interrompido antes da recriação. A aplicação `traçô` tem seu próprio Compose
e workflow de deploy automático, acionado por pushes na branch `master` do
repositório `EvandroNetoo/tra--`.

### Validar e aplicar no servidor

Com o aplicativo no ar, a rede `proxy` criada e os certificados instalados:

```bash
cd /caminho/para/nginx-superintegra
docker compose config --quiet
docker compose run --rm nginx nginx -t
docker compose up -d --force-recreate nginx
```

O teste em um container temporário renderiza os templates usando o novo `.env`.
A recriação atualiza também as variáveis do container principal. Depois confira:

```bash
curl -I https://traco.run/
docker compose logs --tail=50 nginx
```

O Nginx sobrescreve `X-Forwarded-Proto` com `$scheme` no include
`nginx/django_proxy.conf`. Os settings do Django configuram explicitamente
`SECURE_PROXY_SSL_HEADER` para reconhecer HTTPS, gerar o callback correto e validar CSRF.
Mantenha a porta do aplicativo acessível apenas pela rede Docker.

O workflow executa os comandos por `appleboy/ssh-action`, usando os secrets
`SSH_HOST`, `SSH_USER`, `SSH_PRIVATE_KEY` e `SSH_PORT` (opcional, padrão 22).
`SSH_FINGERPRINT` permite verificar a chave de host diretamente nessa action.
O checkout no servidor fica em `$HOME/nginx-superintegra`; o deploy aplica
o commit que disparou a execução. O Nginx precisa ser recriado para renderizar
os templates montados pelo host, mesmo quando a imagem não muda.

Referências: [Cloudflare Origin CA](https://developers.cloudflare.com/ssl/origin-configuration/origin-ca/),
[Full (strict)](https://developers.cloudflare.com/ssl/origin-configuration/ssl-modes/full-strict/)
e [registros DNS](https://developers.cloudflare.com/dns/manage-dns-records/how-to/create-dns-records/).
