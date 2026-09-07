# frozen_string_literal: true

require "mail"

# Configuração da gem Mail para envio de e-mails.
# As credenciais e o servidor SMTP vêm de variáveis de ambiente (.env), nunca
# fixadas no código-fonte (ver .dev/SECURITY.md).

# Modo de envio: "smtp" (padrão) entrega as mensagens no servidor configurado;
# "test" coleta as mensagens em memória (Mail::TestMailer), isolando a suíte de
# testes do servidor real.
EMAIL_SENDER_MODE = ENV.fetch("EMAIL_SENDER_MODE", "smtp").freeze

# Remetente padrão dos e-mails.
MAIL_FROM = ENV.fetch("MAIL_FROM", "no-reply@example.com").freeze

Mail.defaults do
  if EMAIL_SENDER_MODE == "test"
    delivery_method :test
  else
    delivery_method :smtp,
                    address: ENV.fetch("SMTP_ADDRESS", "localhost"),
                    port: ENV.fetch("SMTP_PORT", "587").to_i,
                    domain: ENV.fetch("SMTP_DOMAIN", "localhost"),
                    user_name: ENV.fetch("SMTP_USERNAME", nil),
                    password: ENV.fetch("SMTP_PASSWORD", nil),
                    authentication: ENV.fetch("SMTP_AUTHENTICATION", "plain").to_sym,
                    enable_starttls_auto: ENV.fetch("SMTP_ENABLE_STARTTLS", "true") == "true",
                    open_timeout: 10,
                    read_timeout: 10
  end
end
