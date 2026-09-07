# frozen_string_literal: true

# Configuração do ambiente: dependências (Bundler) e camadas de app/.
require "bundler/setup"
require "dotenv/load"
require "sinatra/base"
require "json"

# Redis/Sidekiq e gem Mail antes das camadas (workers incluem Sidekiq::Job).
require_relative "sidekiq"
require_relative "mail"

APP_ROOT = File.expand_path("..", __dir__).freeze
APP_ENV = ENV.fetch("APP_ENV", "development").to_sym
APP_NAME = "email-notification-system"

# Camadas carregadas automaticamente: modelos -> mailers -> workers -> controladores.
%w[models mailers workers controllers].each do |layer|
  Dir[File.join(APP_ROOT, "app", layer, "**", "*.rb")].each { |file| require file }
end
