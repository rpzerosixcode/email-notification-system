# frozen_string_literal: true

require "spec_helper"

RSpec.describe App::Notification do
  subject(:notification) do
    described_class.new(to: "cliente@example.com", subject: "Bem-vindo", message: "Conta criada.")
  end

  let(:redis) { FakeRedis.new }

  before { stub_const("REDIS_CLIENT", redis) }

  describe "#valid?" do
    it "aceita uma notificação completa" do
      expect(notification).to be_valid
    end

    it "exige destinatário, assunto e mensagem" do
      vazia = described_class.new(to: "", subject: "", message: "")

      expect(vazia).not_to be_valid
      expect(vazia.errors).to include(
        a_string_matching(/to/),
        a_string_matching(/subject/),
        a_string_matching(/message/)
      )
    end

    it "exige e-mail válido no destinatário" do
      invalida = described_class.new(to: "sem-arroba", subject: "Assunto", message: "Texto")

      expect(invalida).not_to be_valid
      expect(invalida.errors).to include(a_string_matching(/e-mail/))
    end
  end

  describe "#save e .find" do
    it "persiste e recupera a notificação" do
      notification.save

      recuperada = described_class.find(notification.id)

      expect(recuperada).to have_attributes(
        to: "cliente@example.com",
        subject: "Bem-vindo",
        message: "Conta criada.",
        status: "pending"
      )
    end

    it "gera id e timestamps no primeiro save" do
      expect(notification.id).to be_nil

      notification.save

      expect(notification.id).to match(/\A[0-9a-f-]{36}\z/)
      expect(notification.created_at).to match(/\A\d{4}-\d{2}-\d{2}T/)
      expect(notification.updated_at).to match(/\A\d{4}-\d{2}-\d{2}T/)
    end

    it "retorna nil quando a notificação não existe" do
      expect(described_class.find("id-inexistente")).to be_nil
    end
  end

  describe "#mark!" do
    it "atualiza o estado e persiste a mudança" do
      notification.save

      notification.mark!("processed")

      expect(notification).to be_processed
      expect(described_class.find(notification.id).status).to eq("processed")
    end

    it "registra o erro em falhas" do
      notification.save

      notification.mark!("failed", error: "SMTP indisponível")

      recuperada = described_class.find(notification.id)
      expect(recuperada.status).to eq("failed")
      expect(recuperada.error).to eq("SMTP indisponível")
    end

    it "rejeita estados fora do ciclo de vida" do
      expect { notification.mark!("enviado") }.to raise_error(ArgumentError, /status inválido/)
    end
  end
end
