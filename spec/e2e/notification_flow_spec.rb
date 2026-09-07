# frozen_string_literal: true

require "spec_helper"
require_relative "../../app"
require "rack/test"

RSpec.describe "Fluxo completo da notificação" do
  include Rack::Test::Methods

  def app
    App::Web
  end

  let(:redis) { FakeRedis.new }
  let(:enfileirados) { [] }

  before do
    stub_const("REDIS_CLIENT", redis)
    Mail::TestMailer.deliveries.clear

    # Simula o enfileiramento do Sidekiq: o job é coletado para execução manual.
    allow(App::NotificationWorker).to receive(:perform_async) do |notification_id|
      enfileirados << notification_id
    end
  end

  it "vai do disparo HTTP até a entrega do e-mail e o estado processed" do
    post "/notifications",
         JSON.generate(to: "cliente@example.com", subject: "Bem-vindo", message: "Conta criada."),
         { "CONTENT_TYPE" => "application/json" }

    expect(last_response.status).to eq(202)
    id = JSON.parse(last_response.body)["id"]
    expect(enfileirados).to eq([id])

    # Simula o processamento do job pelo Sidekiq.
    App::NotificationWorker.new.perform(id)

    entregue = Mail::TestMailer.deliveries.last
    expect(entregue.to).to eq(["cliente@example.com"])
    expect(entregue.subject).to eq("Bem-vindo")
    expect(entregue.body.decoded).to include("Conta criada.")

    get "/notifications/#{id}"
    corpo = JSON.parse(last_response.body)
    expect(corpo["status"]).to eq("processed")
    expect(corpo["error"]).to be_nil
  end
end
