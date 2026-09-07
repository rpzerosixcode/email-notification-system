# frozen_string_literal: true

require "spec_helper"

RSpec.describe App::NotificationMailer do
  let(:remetente) { "remetente-teste@example.com" }

  before { stub_const("MAIL_FROM", remetente) }

  describe ".notification" do
    subject(:mensagem) do
      described_class.notification(
        to: "cliente@example.com",
        subject: "Resumo diário",
        message: "3 notificações enviadas com sucesso."
      )
    end

    it "compõe uma Mail::Message com destinatário e assunto" do
      expect(mensagem).to be_a(Mail::Message)
      expect(mensagem.to).to eq(["cliente@example.com"])
      expect(mensagem.subject).to eq("Resumo diário")
    end

    it "usa o remetente padrão configurado" do
      expect(mensagem.from).to eq([remetente])
    end

    it "renderiza o template de texto com título, mensagem e rodapé" do
      corpo = mensagem.body.decoded

      expect(corpo).to include(APP_NAME)
      expect(corpo).to include("Resumo diário")
      expect(corpo).to include("=" * "Resumo diário".length)
      expect(corpo).to include("3 notificações enviadas com sucesso.")
      expect(corpo).to include("E-mail automático")
    end

    it "normaliza textos de outras codificações para UTF-8" do
      cp850 = "Resumo diário".encode(Encoding::CP850)

      corpo = described_class.notification(
        to: "cliente@example.com",
        subject: cp850,
        message: "Ok"
      ).body.decoded

      expect(corpo).to include("Resumo diário")
    end
  end
end
