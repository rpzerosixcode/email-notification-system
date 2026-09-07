# frozen_string_literal: true

require "spec_helper"
require_relative "../../../app"
require "rack/test"

RSpec.describe "Rotas de saúde" do
  include Rack::Test::Methods

  def app
    App::Web
  end

  it "responde na raiz com informações da aplicação" do
    get "/"

    expect(last_response.status).to eq(200)
    expect(last_response.body).to include("Email Notification System")
  end

  it "responde o health check em JSON" do
    get "/health"

    expect(last_response.status).to eq(200)
    corpo = JSON.parse(last_response.body)
    expect(corpo["status"]).to eq("ok")
    expect(corpo["app"]).to eq(APP_NAME)
  end
end
