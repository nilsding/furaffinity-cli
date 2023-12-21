# frozen_string_literal: true

require "fileutils"
require "yaml"

module Furaffinity
  class Queue
    include SemanticLogger::Loggable

    FA_QUEUE_DIR = ".fa"

    SUBMISSION_INFO_EXT = ".info.yml"

    SUBMISSION_TEMPLATE = <<~YAML
      ---
      # Submission info for %<file_name>s

      # Required field
      title: ""

      # Required field
      description: |-
        Your description goes here

      # Optional field, keywords separated by spaces
      keywords: ""

      # Required field, one of: [#{Furaffinity::Client::RATING_MAP.keys.join(", ")}]
      rating: general

      # Required field, one of: [#{Furaffinity::Client::SUBMISSION_TYPES.join(", ")}]
      type: submission

      scrap: false
      lock_comments: false

      # Create a new folder to place this submission under, leave blank if none should be created.
      create_folder_name: ""
    YAML

    attr_reader :client, :queue_dir, :queue, :upload_status, :file_info

    # @param client [Furaffinity::Client]
    # @param queue_dir [String]
    def initialize(client, queue_dir)
      @client = client
      @queue_dir = queue_dir
      @queue = []
      @upload_status = {}
      @file_info = {}
    end

    def fa_info_dir = File.join(queue_dir, FA_QUEUE_DIR)

    def fa_info_path(*path) = File.join(fa_info_dir, *path)

    def submission_template_path = fa_info_path("templates", "submission.yml")

    # loads state info from queue dir
    def reload
      logger.trace { "Loading state info" }

      @queue = YAML.safe_load_file(fa_info_path("queue.yml"), permitted_classes: [Symbol])
      @upload_status = YAML.safe_load_file(fa_info_path("status.yml"), permitted_classes: [Symbol])
      @file_info = Dir[File.join(queue_dir, "**/*#{SUBMISSION_INFO_EXT}")].map do |path|
        [path.delete_suffix(SUBMISSION_INFO_EXT).sub(/^#{Regexp.escape(queue_dir)}\/?/, ""), YAML.safe_load_file(path, permitted_classes: [Symbol]).transform_keys(&:to_sym)]
      end.to_h

      logger.trace "Loaded state info", queue:, file_info:
    end

    def init
      if Dir.exist?(queue_dir)
        logger.trace { "Checking if directory #{queue_dir.inspect} is empty" }
        raise Error.new("#{queue_dir.inspect} is not empty") unless Dir.empty?(queue_dir)
      end

      logger.trace { "Creating directory #{fa_info_dir.inspect}" }
      FileUtils.mkdir_p(fa_info_dir)

      %w[templates].each do |dir|
        logger.trace { "Creating directory #{fa_info_path(dir).inspect}" }
        FileUtils.mkdir_p(fa_info_path(dir))
      end

      logger.trace { "Creating empty state files" }
      save

      logger.trace { "Creating submission template" }
      File.open(submission_template_path, "w") do |f|
        f.puts(SUBMISSION_TEMPLATE)
      end

      logger.debug "Created new queue dir in #{queue_dir.inspect}"
      queue_dir
    end

    def add(*files)
      files.select do |file|
        unless File.exist?(file)
          logger.warn "File #{file.inspect} does not exist"
          next false
        end

        if queue.include?(file)
          logger.warn "File #{file.inspect} is already in the queue"
          next false
        end

        submission_info_path = create_submission_info(file)
        CliUtils.open_editor submission_info_path

        queue << file
        upload_status[file] = {
          uploaded: false,
          url:      nil,
        }

        save

        true
      end
    end

    def remove(*files)
      files.select do |file|
        unless queue.include?(file)
          logger.warn "File #{file.inspect} is not in the queue"
          next false
        end

        queue.delete(file)
        upload_status.delete(file)

        save

        true
      end
    end

    def clean
      uploaded_files.each do |file, _upload_info|
        logger.trace { "Deleting #{file} ..." }
        queue.delete(file)
        upload_status.delete(file)
        File.unlink(file)
        File.unlink(file + SUBMISSION_INFO_EXT)
        save
      end
    end

    def reorder
      CliUtils.open_editor fa_info_path("queue.yml")
    end

    def upload(wait_time = 60)
      raise ArgumentError.new("wait_time must be at least 30") if wait_time < 30

      while file_name = queue.shift
        info = file_info[file_name]
        unless info
          logger.warn "no file info found for #{file_name}, ignoring"
          next
        end

        logger.info "Uploading #{info[:title].inspect} (#{file_name.inspect})"
        url = client.upload(
          File.new(file_name),
          **file_info[file_name]
        )

        upload_status[file_name][:uploaded] = true
        upload_status[file_name][:url] = url

        save

        unless queue.empty?
          logger.info "Waiting #{wait_time} seconds until the next upload"
          sleep wait_time
        end
      end
    end

    def uploaded_files
      upload_status.select { _2[:uploaded] }
    end

    def save
      { queue:, status: upload_status }.each do |type, content|
        path = fa_info_path("#{type}.yml")
        logger.trace { "Writing #{path}" }
        yaml_content = content.to_yaml
        File.open(path, "w") do |f|
          f.puts(yaml_content)
        end
      end
    end

    def create_submission_info(file)
      template = File.read(submission_template_path)

      submission_info_path = "#{file}#{SUBMISSION_INFO_EXT}"
      return submission_info_path if File.exist?(submission_info_path)

      rendered_template = format(template, file_name: file.inspect)
      File.open(submission_info_path, "w") do |f|
        f.puts rendered_template
      end

      submission_info_path
    end
  end
end
