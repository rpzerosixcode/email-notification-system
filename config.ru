# frozen_string_literal: true

require "securerandom"
require "sidekiq/web"
require_relative "app"

# Painel do Sidekiq para monitoramento das filas, montado em /sidekiq.
# Proteção por basic auth com SIDEKIQ_WEB_USERNAME/SIDEKIQ_WEB_PASSWORD; sem
# credenciais, o painel só fica acessível em desenvolvimento.
map "/sidekiq" do
  use Rack::Session::Cookie, secret: ENV.fetch("SIDEKIQ_WEB_SECRET", SecureRandom.hex(32))

  use Rack::Auth::Basic, "Sidekiq" do |username, password|
    if ENV["SIDEKIQ_WEB_USERNAME"] && ENV["SIDEKIQ_WEB_PASSWORD"]
      Rack::Utils.secure_compare(username.to_s, ENV.fetch("SIDEKIQ_WEB_USERNAME")) &&
        Rack::Utils.secure_compare(password.to_s, ENV.fetch("SIDEKIQ_WEB_PASSWORD"))
    else
      APP_ENV == :development
    end
  end

  run Sidekiq::Web
end

run App::Web
