# frozen_string_literal: true

module Furaffinity
  module CliBase
    def self.included(base)
      def base.exit_on_failure? = true
    end

    private

    def set_log_level(options)
      SemanticLogger.default_level = options[:log_level].to_sym
    end

    def config_for(options) = Config.new(options[:config])
  end
end
