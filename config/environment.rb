# frozen_string_literal: true

# Configuração do ambiente da aplicação.
# Carrega as dependências (Bundler) e as camadas de app/ em ordem.

require "bundler/setup"
require "dotenv/load"
require "sinatra/base"
require "json"

require_relative "sidekiq" # Sidekiq/Redis — deve vir antes das camadas de app/ (workers incluem Sidekiq::Job).

APP_ROOT = File.expand_path("..", __dir__)
APP_ENV  = ENV.fetch("APP_ENV", "development").to_sym

# Ordem de carregamento das camadas: modelos -> serviços -> mailers -> workers -> controladores.
%w[models services mailers workers controllers].each do |layer|
  Dir[File.join(APP_ROOT, "app", layer, "**", "*.rb")].each { |file| require file }
end
