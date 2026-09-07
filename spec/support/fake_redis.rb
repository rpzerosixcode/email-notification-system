# frozen_string_literal: true

# Falso cliente Redis (compatível com a interface redis-client usada pelo
# projeto) em memória, para testes unitários e de integração sem Redis real.
class FakeRedis
  attr_reader :store

  def initialize
    @store = {}
  end

  def call(command, *args)
    case command.to_s.upcase
    when "SET" then @store[args.fetch(0)] = args.fetch(1)
    when "GET" then @store[args.fetch(0)]
    else raise NotImplementedError, "comando não simulado no FakeRedis: #{command}"
    end
  end
end
