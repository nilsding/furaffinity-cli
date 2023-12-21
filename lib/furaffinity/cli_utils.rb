# frozen_string_literal: true

require "shellwords"

module Furaffinity
  module CliUtils
    module_function

    include SemanticLogger::Loggable

    def open_editor(file, fatal: false)
      editor = ENV["FA_EDITOR"] || ENV["VISUAL"] || ENV["EDITOR"]
      unless editor
        logger.warn "could not open editor for #{file.inspect}, set one of FA_EDITOR, VISUAL, or EDITOR in your ENV"
        raise "No suitable editor found to edit #{file.inspect}, set one of FA_EDITOR, VISUAL, or EDITOR in your ENV" if fatal

        return
      end

      system(*Shellwords.shellwords(editor), file).tap do
        next if $?.exitstatus == 0

        logger.error "could not run #{editor} #{file}, exit code: #{$?.exitstatus}"
      end
    end
  end
end
