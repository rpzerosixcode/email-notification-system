# Arquitetura

## Camadas

### Ponto de Entrada (Web)

`config.ru`, `app.rb`

A aplicação é inicializada pelo Rack: `config.ru` carrega o `app.rb` e executa
`App::Web` (subclasse de `Sinatra::Base`). O servidor web é o Puma, subido com
`bundle exec rackup`.

Responsável por:

* Definir as rotas HTTP (`GET /` e `GET /health`).
* Montar o controlador da API de notificações e o painel do Sidekiq
  (`/sidekiq`, em `config.ru`).
* Responder o status da aplicação em JSON no endpoint `/health`.

### Configuração do Ambiente

`config/environment.rb`, `config/sidekiq.rb`, `config/sidekiq.yml`,
`config/mail.rb`

Carrega as dependências (Bundler), as variáveis de ambiente (Dotenv, via
`.env`) e configura a integração com o Redis e o Sidekiq.

Responsável por:

* Definir `APP_ROOT` e `APP_ENV`.
* Configurar as conexões com o Redis (`REDIS_URL`), incluindo o `REDIS_CLIENT`
  para persistência de domínio e o servidor/cliente do Sidekiq.
* Carregar automaticamente as camadas de aplicação em `app/`.
* Configurar a gem `mail` para o envio de e-mails (`EMAIL_SENDER_MODE`, `SMTP_*`
  e `MAIL_FROM`), com modo `test` que coleta as mensagens em memória.

### Camadas de Aplicação

`app/models`, `app/services`, `app/mailers`, `app/workers`, `app/controllers`

As pastas são carregadas automaticamente por `config/environment.rb` e todas as
camadas têm implementações.

Responsável por:

* `models` — representar o domínio (ex.: Notificação).
* `services` — conter a lógica de negócio (ex.: orquestrar o envio de e-mail via SMTP).
* `mailers` — compor as mensagens de e-mail em texto simples (destinatário,
  assunto, corpo) com a gem `mail`.
* `workers` — processar jobs do Sidekiq na fila `notifications`.
* `controllers` — receber requisições HTTP e orquestrar os serviços.

### Infraestrutura Externa

`Redis`, `SMTP`

O Redis armazena as filas do Sidekiq e os dados de notificação; o SMTP é o
canal de entrega dos e-mails.

## Fluxo de Dados

Fluxo implementado:

```text
[POST /notifications]
      |
      +-- [Controlador] --> [Notificação no Redis: pending]
      |                           |
      |                           +-- [Sidekiq: fila notifications]
      |                                     |
      |                                     +-- [Worker] --> [Mailer] --> [EmailSender] --> [SMTP]
      |                                           |                                           |
      |                                           +-- falha --> [failed] + [retries]         +-- entrega --> [processed]
      |
      +-- [GET /notifications/:id] --> JSON com o estado atual

[GET /health] --> JSON de status
```

## Testes

A suíte usa RSpec com especificações nos três níveis e é hermética: o Redis é
simulado (`FakeRedis`) e os e-mails são coletados em memória (modo `test` da
gem Mail), sem nenhum serviço externo. Execução: `bundle exec rake` (suíte
completa) ou `rake unit`, `rake integration` e `rake e2e` (por nível).

| Caminho | Escopo |
| --- | --- |
| `spec/unit` | Modelos, mailers, serviços e workers testados de forma isolada. |
| `spec/integration` | Rotas Sinatra (via `rack-test`), com o Redis simulado. |
| `spec/e2e` | Fluxo completo da notificação, do disparo HTTP à entrega do e-mail. |
| `spec/support` | Arquivos de apoio compartilhados (ex.: `FakeRedis`), carregados automaticamente. |
| `spec/fixtures` | Arquivos de dados de exemplo usados pelos testes. |

O `spec/spec_helper.rb` define `APP_ENV=test` e carrega o ambiente por
`config/environment.rb`.

## Decisões de Design

### Sinatra como framework web

Leve e baseado em Rack, suficiente para as rotas atuais e futuras do sistema,
sem o custo de um framework completo.

### Sidekiq sobre Redis para filas assíncronas

O envio de e-mails é processado em segundo plano, desacoplado da resposta HTTP,
com possibilidade de retries. A fila `notifications` é priorizada em
`config/sidekiq.yml`.

### Gem `mail` para envio via SMTP

Biblioteca para compor e enviar mensagens via SMTP, com suporte a STARTTLS.

### Puma + rackup como servidor web

Puma é o servidor HTTP; `rackup` fornece o executável utilizado por
`bundle exec rackup`.

### Dotenv para configuração por ambiente

As configurações da aplicação são carregadas por variáveis de ambiente a
partir de `.env`; o `.env.example` serve como modelo com valores genéricos.