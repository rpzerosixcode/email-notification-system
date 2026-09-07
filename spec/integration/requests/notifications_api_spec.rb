# frozen_string_literal: true

require "spec_helper"
require_relative "../../../app"
require "rack/test"

RSpec.describe "API de notificações" do
  include Rack::Test::Methods

  def app
    App::Web
  end

  let(:redis) { FakeRedis.new }

  before { stub_const("REDIS_CLIENT", redis) }

  describe "POST /notifications" do
    let(:payload) do
      JSON.generate(to: "cliente@example.com", subject: "Bem-vindo", message: "Conta criada.")
    end

    it "aceita a solicitação, persiste e enfileira o processamento" do
      enfileirados = []
      allow(App::NotificationWorker).to receive(:perform_async) do |notification_id|
        enfileirados << notification_id
      end

      post "/notifications", payload, { "CONTENT_TYPE" => "application/json" }

      expect(last_response.status).to eq(202)
      corpo = JSON.parse(last_response.body)
      expect(corpo["id"]).to match(/\A[0-9a-f-]{36}\z/)
      expect(corpo["status"]).to eq("pending")

      expect(enfileirados).to eq([corpo["id"]])
      expect(App::Notification.find(corpo["id"]).status).to eq("pending")
    end

    it "rejeita corpo que não é um JSON válido" do
      post "/notifications", "nao-e-json", { "CONTENT_TYPE" => "application/json" }

      expect(last_response.status).to eq(400)
    end

    it "rejeita solicitações com campos inválidos" do
      post "/notifications",
           JSON.generate(to: "sem-arroba", subject: "", message: ""),
           { "CONTENT_TYPE" => "application/json" }

      expect(last_response.status).to eq(422)
      corpo = JSON.parse(last_response.body)
      expect(corpo["errors"]).not_to be_empty
    end
  end

  describe "GET /notifications/:id" do
    it "retorna o estado atual da notificação" do
      notification = App::Notification.new(
        to: "cliente@example.com",
        subject: "Bem-vindo",
        message: "Conta criada."
      ).save

      get "/notifications/#{notification.id}"

      expect(last_response.status).to eq(200)
      corpo = JSON.parse(last_response.body)
      expect(corpo["id"]).to eq(notification.id)
      expect(corpo["to"]).to eq("cliente@example.com")
      expect(corpo["status"]).to eq("pending")
    end

    it "retorna 404 quando a notificação não existe" do
      get "/notifications/id-inexistente"

      expect(last_response.status).to eq(404)
    end
  end
end
