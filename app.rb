# frozen_string_literal: true

require_relative "config/environment"

module App
  # Aplicação web principal (Sinatra): API de notificações e rotas de saúde.
  class Web < Sinatra::Base
    configure do
      set :root, APP_ROOT
    end

    use NotificationsController

    get "/" do
      "Email Notification System - Sinatra #{Sinatra::VERSION}"
    end

    get "/health" do
      content_type :json

      JSON.generate(
        status: "ok",
        app: APP_NAME,
        sinatra: Sinatra::VERSION,
        ruby: RUBY_VERSION
      )
    end

    run! if app_file == $PROGRAM_NAME
  end
end
