# frozen_string_literal: true

require_relative 'support/coverage'
require_relative 'support/warnings'

Warning.ignore(%r{gems/i18n})

begin
  require 'pry-byebug'
rescue LoadError; end
SPEC_ROOT = Pathname(__dir__)

Dir[SPEC_ROOT.join('shared/**/*.rb')].each(&method(:require))
Dir[SPEC_ROOT.join('support/**/*.rb')].each(&method(:require))

require 'dry/schema'
require 'dry/types'

module Types
  include Dry.Types
end

Undefined = Dry::Core::Constants::Undefined

Dry::Schema.load_extensions(:hints)

require 'i18n'
require 'transproc/all'

require 'dry/schema/messages/i18n'
require 'dry/schema/message_set'

module MessageSetSupport
  def eql?(other)
    to_h.eql?(other)
  end
end

module Coercions
  extend Transproc::Registry

  import Transproc::Recursion
  import Transproc::HashTransformations

  T = self

  def stringify_keys(hash)
    T[:hash_recursion, T[:stringify_keys]].(hash)
  end
end

Dry::Schema::MessageSet.include(MessageSetSupport)

RSpec.configure do |config|
  unless RUBY_VERSION >= '2.7'
    config.exclude_pattern = '**/pattern_matching_spec.rb'
  end
  config.disable_monkey_patching!
  config.filter_run_when_matching :focus

  config.include PredicatesIntegration
  config.include Coercions

  config.define_derived_metadata do |meta|
    meta[:aggregate_failures] = true
  end

  config.before do
    stub_const('Test', Module.new)
  end

  config.after do
    I18n.load_path = [Dry::Schema::DEFAULT_MESSAGES_PATH]
    I18n.locale = :en
    I18n.reload!

    %i[YAML I18n].each do |backend|
      Dry::Schema::Messages.const_get(backend).instance_variable_set('@cache', nil)
    end
  end
end
