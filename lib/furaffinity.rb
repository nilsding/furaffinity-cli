# frozen_string_literal: true

require "semantic_logger"
require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.setup

module Furaffinity
  class Error < StandardError; end
end
