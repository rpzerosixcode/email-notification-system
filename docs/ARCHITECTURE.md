# Arquitetura

## Camadas

### Ponto de Entrada (Web)

`config.ru`, `app.rb`

A aplicação é inicializada pelo Rack: `config.ru` carrega o `app.rb` e executa
`App` (subclasse de `Sinatra::Base`). O servidor web é o Puma, subido com
`bundle exec rackup`.

Responsável por:

* Definir as rotas HTTP (`GET /` e `GET /health`).
* Responder o status da aplicação em JSON no endpoint `/health`.

### Configuração do Ambiente

`config/environment.rb`, `config/sidekiq.rb`, `config/sidekiq.yml`

Carrega as dependências (Bundler), as variáveis de ambiente (Dotenv, via
`.env`) e configura a integração com o Redis e o Sidekiq.

Responsável por:

* Definir `APP_ROOT` e `APP_ENV`.
* Configurar as conexões com o Redis (`REDIS_URL`), incluindo o `REDIS_CLIENT`
  para persistência de domínio e o servidor/cliente do Sidekiq.
* Carregar automaticamente as camadas de aplicação em `app/`.

### Camadas de Aplicação (a implementar)

`app/models`, `app/services`, `app/mailers`, `app/workers`, `app/controllers`

As pastas existem e são carregadas automaticamente por `config/environment.rb`,
mas ainda estão vazias.

Responsável por:

* `models` — representar o domínio (ex.: Notificação).
* `services` — conter a lógica de negócio (ex.: orquestrar o envio de e-mail via SMTP).
* `mailers` — compor as mensagens de e-mail (destinatário, assunto, corpo) com a
  gem `mail`.
* `workers` — processar jobs do Sidekiq na fila `notifications`.
* `controllers` — receber requisições HTTP e orquestrar os serviços.

### Infraestrutura Externa

`Redis`, `SMTP`

O Redis armazena as filas do Sidekiq e os dados de notificação; o SMTP é o
canal de entrega dos e-mails.

## Fluxo de Dados

Estado atual (health check):

```text
[GET /health]
      |
      +-- [app.rb / Sinatra] --> JSON de status
```

Fluxo planejado:

```text
[Requisicao HTTP]
      |
      +-- [Controlador] --> [Servico] --> [SMTP] --> [Servidor de E-mail]
      |                                             |
      |                                             +-- falha --> [Erro/log]
      |
      +-- [Worker Sidekiq] --> [Redis: fila notifications]
                                      |
                                      +-- falha --> [Retries do Sidekiq]
```

## Testes

A suíte usa RSpec e a estrutura já está criada, embora as especificações ainda
não estejam implementadas. Execução: `bundle exec rake` (suíte completa) ou
`rake unit`, `rake integration` e `rake e2e` (por nível).

| Caminho | Escopo |
| --- | --- |
| `spec/unit` | Modelos e serviços testados de forma isolada (dependências simuladas). |
| `spec/integration` | Interação com o Redis e o SMTP, e as rotas Sinatra (via `rack-test`). |
| `spec/e2e` | Fluxo completo da notificação, do disparo da requisição até a entrega do e-mail. |
| `spec/support` | Arquivos de apoio compartilhados pelos testes, carregados automaticamente. |
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