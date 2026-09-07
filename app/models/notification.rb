# frozen_string_literal: true

require "json"
require "securerandom"
require "time"

module App
  # Modelo de domínio da notificação, persistido no Redis como JSON na chave
  # notification:<id>. Ciclo de vida: pending -> processing -> processed/failed.
  class Notification
    STATUSES = %w[pending processing processed failed].freeze
    EMAIL_REGEX = /\A[^@\s]+@[^@\s]+\z/
    KEY_PREFIX = "notification:"

    attr_reader :id, :to, :subject, :message, :status, :error, :created_at, :updated_at

    def initialize(to:, subject:, message:, id: nil, status: "pending", error: nil,
                   created_at: nil, updated_at: nil)
      @id = id
      @to = to.to_s
      @subject = subject.to_s
      @message = message.to_s
      @status = status.to_s
      @error = error
      @created_at = created_at
      @updated_at = updated_at
    end

    # Busca a notificação persistida; retorna nil quando não existe.
    def self.find(id, redis: REDIS_CLIENT)
      data = redis.call("GET", key_for(id))
      data && from_json(data)
    end

    def self.key_for(id)
      "#{KEY_PREFIX}#{id}"
    end

    def self.from_json(json)
      new(**JSON.parse(json, symbolize_names: true))
    end

    # Validações da solicitação de envio.
    def valid?
      errors.empty?
    end

    def errors
      list = []
      list << "to é obrigatório" if @to.strip.empty?
      list << "to deve ser um e-mail válido" if !@to.strip.empty? && !@to.match?(EMAIL_REGEX)
      list << "subject é obrigatório" if @subject.strip.empty?
      list << "message é obrigatória" if @message.strip.empty?
      list
    end

    # Persiste no Redis, gerando id e timestamps no primeiro save.
    def save(redis: REDIS_CLIENT)
      @id ||= SecureRandom.uuid
      now = Time.now.utc.iso8601
      @created_at ||= now
      @updated_at = now
      redis.call("SET", self.class.key_for(@id), to_json)
      self
    end

    # Atualiza o estado da notificação e persiste a mudança.
    def mark!(new_status, error: nil, redis: REDIS_CLIENT)
      raise ArgumentError, "status inválido: #{new_status}" unless STATUSES.include?(new_status)

      @status = new_status
      @error = error
      save(redis: redis)
      self
    end

    def processed?
      @status == "processed"
    end

    def to_h
      { id: @id, to: @to, subject: @subject, message: @message, status: @status,
        error: @error, created_at: @created_at, updated_at: @updated_at }
    end

    def to_json(*)
      JSON.generate(to_h)
    end
  end
end
