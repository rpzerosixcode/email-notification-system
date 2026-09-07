# frozen_string_literal: true

module App
  # Processa as notificações da fila "notifications": entrega o e-mail e registra o estado.
  class NotificationWorker
    include Sidekiq::Job

    sidekiq_options queue: "notifications", retry: 5

    def perform(notification_id)
      notification = Notification.find(notification_id)
      return unless notification

      # Idempotência: não reenvia o que já saiu.
      return if notification.processed?

      notification.mark!("processing")

      message = NotificationMailer.notification(
        to: notification.to,
        subject: notification.subject,
        message: notification.message
      )
      message.deliver!
      notification.mark!("processed")
    rescue StandardError => e
      notification&.mark!("failed", error: e.message)
      raise # repassa ao Sidekiq para a retentativa
    end
  end
end
