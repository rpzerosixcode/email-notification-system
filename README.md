# Sistema de Notificação por E-mail

Sistema de envio de notificações por e-mail via SMTP, com processamento
assíncrono de filas (Sidekiq sobre Redis) e uma interface web leve em Sinatra.

## Requisitos

* Ruby **3.2** ou superior (desenvolvido e testado com Ruby 4.0.5).
* Redis **6** ou superior, acessível via `REDIS_URL`.
* Um servidor SMTP acessível com as credenciais definidas no `.env`.
* Dependências Ruby instaladas com o Bundler (veja o `Gemfile`).

## Instalação

### A partir do código-fonte

No Linux (Debian/Ubuntu), o Ruby e o Redis podem ser instalados pelo
gerenciador de pacotes:

```console
$ sudo apt-get install ruby-full build-essential redis-server
```

Com o Ruby e o Bundler disponíveis:

```console
$ git clone [URL do repositório]
$ cd email-notification-system
$ bundle install
```

Copie o modelo das variáveis de ambiente e ajuste os valores:

```console
$ cp .env.example .env
```

No Windows PowerShell, use: `Copy-Item .env.example .env`.

O `Gemfile.lock` é resolvido para Windows (`x64-mingw-ucrt`) e para Linux
(`x86_64-linux` e `aarch64-linux`), permitindo implantar em servidores Linux
sem regenerar o lock.

## Configuração

Antes de usar a aplicação, defina as variáveis de ambiente necessárias:

| Variável | Descrição |
| ----------------- | ----------------------------------- |
| `REDIS_URL` | URL de conexão com o Redis usada pelo Sidekiq (padrão: `redis://localhost:6379/0`). |
| `EMAIL_SENDER_MODE` | Modo de envio de e-mails (`smtp`). |
| `SMTP_ADDRESS` | Endereço do servidor SMTP. |
| `SMTP_PORT` | Porta do servidor SMTP (padrão: `587`). |
| `SMTP_USERNAME` | Usuário de autenticação no SMTP. |
| `SMTP_PASSWORD` | Senha de autenticação no SMTP. |
| `SMTP_AUTHENTICATION` | Método de autenticação (ex.: `plain`). |
| `SMTP_ENABLE_STARTTLS` | Habilita ou desabilita STARTTLS (`true`/`false`). |
| `SMTP_DOMAIN` | Domínio usado na conexão SMTP. |
| `MAIL_FROM` | Remetente padrão dos e-mails. |
| `SIDEKIQ_WEB_USERNAME` | Usuário do basic auth do painel do Sidekiq (opcional). |
| `SIDEKIQ_WEB_PASSWORD` | Senha do basic auth do painel do Sidekiq (opcional). |
| `SIDEKIQ_WEB_SECRET` | Segredo da sessão do painel do Sidekiq (opcional). |

Um modelo preenchível está disponível em `.env.example`.

As credenciais e as configurações sensíveis são carregadas apenas por
variáveis de ambiente (`.env`), arquivo ignorado pelo Git e que nunca deve
ser versionado.

## Uso

### Iniciar o servidor web

```console
$ bundle exec rackup
```

A aplicação responde em `http://localhost:9292`:

* `GET /` — informações da aplicação e versão do Sinatra.
* `GET /health` — status de saúde da aplicação em JSON (health check).

### Processar as filas de notificação

```console
$ bundle exec sidekiq
```

O Sidekiq carrega `config/sidekiq.yml` automaticamente, requisita
`config/environment.rb` e processa as filas `notifications` e `default`
com 5 threads de concorrência.

### API de notificações

Disparar uma notificação (o envio é processado em segundo plano pelo Sidekiq):

```console
$ curl -X POST http://localhost:9292/notifications \
    -H "Content-Type: application/json" \
    -d '{"to": "cliente@example.com", "subject": "Bem-vindo", "message": "Conta criada."}'
```

* `POST /notifications` — recebe `{ to, subject, message }`, persiste a
  notificação e enfileira o processamento (`202 Accepted`).
* `GET /notifications/:id` — retorna o estado da notificação (`pending`,
  `processing`, `processed`, `failed`).

### Painel do Sidekiq

Com o servidor no ar, o painel fica em `http://localhost:9292/sidekiq`. Sem
`SIDEKIQ_WEB_USERNAME` e `SIDEKIQ_WEB_PASSWORD`, ele só fica acessível em
desenvolvimento; em produção, defina as credenciais (basic auth).

## Testes

A suíte usa RSpec com especificações nos três níveis e é hermética: o Redis é
simulado (`FakeRedis`) e os e-mails são coletados em memória (modo `test` da
gem Mail), sem nenhum serviço externo. Execução: `bundle exec rake` (suíte
completa), `rake unit`, `rake integration` e `rake e2e` (por nível) e
`bundle exec rubocop` (lint).

## Licença

[Licença MIT](./LICENSE) — permissões de uso, cópia, modificação e
distribuição, mediante aviso de direitos autorais e sem garantias.