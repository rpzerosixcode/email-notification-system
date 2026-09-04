# frozen_string_literal: true

require_relative "config/environment"

# Aplicação principal do sistema de notificações por e-mail.
class App < Sinatra::Base
  configure do
    set :root, APP_ROOT
  end

  get "/" do
    "Email Notification System - Sinatra #{Sinatra::VERSION}"
  end

  get "/health" do
    content_type :json

    # Verifica se a aplicação está funcionando.
    JSON.generate(
      status: "ok",
      app: "email-notification-system",
      sinatra: Sinatra::VERSION,
      ruby: RUBY_VERSION
    )
  end

  run! if app_file == $PROGRAM_NAME
end
