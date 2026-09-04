# frozen_string_literal: true

require "sidekiq"
require "redis-client"

# Configuração de conexão do Sidekiq com o Redis.
# A URL pode ser sobrescrita via REDIS_URL (padrão: redis://localhost:6379/0).
REDIS_URL = ENV.fetch("REDIS_URL", "redis://localhost:6379/0").freeze

Sidekiq.configure_server do |config|
  config.redis = { url: REDIS_URL }
end

Sidekiq.configure_client do |config|
  config.redis = { url: REDIS_URL }
end

# Cliente Redis compartilhado para persistência de domínio (Notificações).
REDIS_CLIENT = RedisClient.new(url: REDIS_URL)
