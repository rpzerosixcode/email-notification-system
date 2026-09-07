# frozen_string_literal: true

module App
  # Compõe as mensagens de e-mail de notificação em texto simples, sem HTML.
  # O remetente e o modo de entrega vêm da configuração de config/mail.rb.
  class NotificationMailer
    def self.notification(to:, subject:, message:)
      recipient = to.to_s
      subject_line = normalize(subject)
      content = body(subject_line, normalize(message))

      Mail.new do
        from MAIL_FROM
        to recipient
        subject subject_line
        body content
      end
    end

    # Converte o texto para UTF-8 (codificação dos templates e da gem Mail),
    # tolerando entradas em outras codificações, como o console do Windows.
    def self.normalize(text)
      text.to_s.encode(Encoding::UTF_8, invalid: :replace)
    end

    # Template do corpo em texto simples: cabeçalho da aplicação, título,
    # separador, mensagem e rodapé automático.
    def self.body(subject, message)
      <<~TEXT
        #{APP_NAME}

        #{subject}
        #{'=' * subject.length}

        #{message}

        --
        E-mail automático do #{APP_NAME} — não responda.
      TEXT
    end
  end
end
