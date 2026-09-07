# frozen_string_literal: true

require "spec_helper"

RSpec.describe App::NotificationWorker do
  subject(:worker) { described_class.new }

  let(:redis) { FakeRedis.new }
  let(:notification) do
    App::Notification.new(
      to: "cliente@example.com",
      subject: "Bem-vindo",
      message: "Conta criada."
    ).save
  end

  before do
    stub_const("REDIS_CLIENT", redis)
    Mail::TestMailer.deliveries.clear
  end

  context "quando a notificação está pendente" do
    it "entrega o e-mail e marca como processed" do
      worker.perform(notification.id)

      entregue = Mail::TestMailer.deliveries.last
      expect(entregue.to).to eq(["cliente@example.com"])
      expect(entregue.subject).to eq("Bem-vindo")
      expect(entregue.body.decoded).to include("Conta criada.")

      expect(App::Notification.find(notification.id).status).to eq("processed")
    end
  end

  context "quando a notificação não existe" do
    it "ignora o job sem falhar" do
      expect { worker.perform("id-inexistente") }.not_to raise_error
      expect(Mail::TestMailer.deliveries).to be_empty
    end
  end

  context "quando a notificação já foi processada" do
    it "não entrega novamente" do
      notification.mark!("processed")

      expect { worker.perform(notification.id) }.not_to(change { Mail::TestMailer.deliveries.size })
    end
  end

  context "quando o envio falha" do
    it "marca como failed e repassa o erro ao Sidekiq" do
      mensagem = instance_double(Mail::Message)
      allow(mensagem).to receive(:deliver!).and_raise(StandardError, "SMTP indisponível")
      allow(App::NotificationMailer).to receive(:notification).and_return(mensagem)

      expect { worker.perform(notification.id) }.to raise_error(StandardError, /SMTP indisponível/)

      recuperada = App::Notification.find(notification.id)
      expect(recuperada.status).to eq("failed")
      expect(recuperada.error).to eq("SMTP indisponível")
    end
  end
end
