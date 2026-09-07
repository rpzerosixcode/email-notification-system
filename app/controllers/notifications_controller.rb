# frozen_string_literal: true

module App
  # API de notificações: persiste { to, subject, message } no Redis,
  # enfileira o processamento no Sidekiq e devolve o estado em JSON.
  class NotificationsController < Sinatra::Base
    before { content_type :json, charset: "utf-8" }

    post "/notifications" do
      payload = parsed_body

      notification = Notification.new(
        to: payload["to"],
        subject: payload["subject"],
        message: payload["message"]
      )

      return json_errors(notification.errors) unless notification.valid?

      notification.save
      NotificationWorker.perform_async(notification.id)

      status 202
      notification_json(notification)
    end

    get "/notifications/:id" do
      notification = Notification.find(params[:id])

      return json_error(404, "notificação não encontrada") unless notification

      notification_json(notification)
    end

    private

    # Lê o corpo JSON da requisição (400 quando inválido).
    def parsed_body
      payload = JSON.parse(request.body.read)

      return payload if payload.is_a?(Hash)

      json_error(400, "corpo da requisição deve ser um objeto JSON")
    rescue JSON::ParserError
      json_error(400, "corpo da requisição deve ser um JSON válido")
    end

    # Responde { "errors": [...] } e corta a requisição (422).
    def json_errors(messages)
      halt 422, JSON.generate(errors: messages)
    end

    # Responde { "error": message } e corta a requisição.
    def json_error(status, message)
      halt status, JSON.generate(error: message)
    end

    # Representação JSON da notificação nas respostas da API.
    def notification_json(notification)
      JSON.generate(
        id: notification.id,
        to: notification.to,
        subject: notification.subject,
        message: notification.message,
        status: notification.status,
        error: notification.error,
        created_at: notification.created_at,
        updated_at: notification.updated_at,
        status_url: "/notifications/#{notification.id}"
      )
    end
  end
end