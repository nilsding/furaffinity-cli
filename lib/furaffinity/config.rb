# frozen_string_literal: true

require "yaml"

module Furaffinity
  class Config
    include SemanticLogger::Loggable

    def initialize(path)
      @path = path
      if File.exist?(path)
        logger.measure_trace("Loading configuration") do
          @config_hash = YAML.safe_load_file(path)
        end
      else
        @config_hash = {}
      end
    rescue => e
      logger.fatal("Error while loading configuration:", e)
      raise
    end

    # @return [Furaffinity::Client]
    def new_client = Furaffinity::Client.new(a: self[:a], b: self[:b])

    def [](key) = @config_hash[key.to_s]
    alias get []

    def []=(key, value)
      @config_hash[key.to_s] = value
    end

    def set(**kwargs)
      kwargs.each do |k, v|
        self[k] = v
      end
    end

    def set!(**kwargs)
      set(**kwargs)
      save
    end

    def save
      logger.measure_debug("Saving configuration") do
        yaml = @config_hash.to_yaml
        File.open(@path, "w") do |f|
          f.puts yaml
        end
      end
    end
  end
end
