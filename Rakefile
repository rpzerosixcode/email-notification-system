# frozen_string_literal: true

require "rspec/core/rake_task"

# Testes

desc "Executa os testes unitários"
RSpec::Core::RakeTask.new(:unit) { |t| t.pattern = "spec/unit/**/*_spec.rb" }

desc "Executa os testes de integração"
RSpec::Core::RakeTask.new(:integration) { |t| t.pattern = "spec/integration/**/*_spec.rb" }

desc "Executa os testes de ponta a ponta (E2E)"
RSpec::Core::RakeTask.new(:e2e) { |t| t.pattern = "spec/e2e/**/*_spec.rb" }

desc "Executa toda a suíte de testes"
task default: %i[unit integration e2e]

# RuboCop

begin
  require "rubocop/rake_task"
  RuboCop::RakeTask.new(:rubocop)
rescue LoadError
  task :rubocop do
    abort "RuboCop não está instalado. Rode `bundle install` primeiro."
  end
end
