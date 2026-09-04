# frozen_string_literal: true

source "https://rubygems.org"

# Framework web
gem "sinatra", "~> 4.1"

# Executável rackup (Rack 3 não o inclui mais; Sinatra não o traz como dependência)
gem "rackup", "~> 2.3"

# Servidor de aplicação
gem "puma", "~> 8.0"

# Filas assíncronas (Sidekiq sobre Redis)
gem "sidekiq", "~> 8.0"

# Envio de e-mails (SMTP)
gem "mail", "~> 2.8"

# Carregamento automático das variáveis de ambiente a partir do .env
gem "dotenv", "~> 3.1"

group :development, :test do
  # Tarefas de automação (testes, lint, etc.)
  gem "rake", "~> 13.0"

  # Framework de testes
  gem "rspec", "~> 3.13"

  # Testes das rotas Sinatra
  gem "rack-test", "~> 2.2"

  # Lint Ruby
  gem "rubocop", "~> 1.90"
  gem "rubocop-performance", "~> 1.27"
end
