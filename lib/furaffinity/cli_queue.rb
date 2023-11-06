# frozen_string_literal: true

require "thor"

module Furaffinity
  class CliQueue < Thor
    include CliBase

    desc "init [DIR]", "Initialise a queue directory"
    def init(dir = Dir.pwd)
      result = queue(dir).init
      say "Created new queue dir in #{result.inspect}", :green
    rescue Furaffinity::Error => e
      say e.message, :red
      exit 1
    end

    desc "add FILE...", "Add a file to the upload queue"
    def add(*files)
      if files.empty?
        say "You need to pass a file.", :red
        help :add
        exit 1
      end

      queue.reload

      files_added = queue.add(*files)
      files_added.each do |file|
        say "added #{file.inspect}", :green
      end
    rescue Furaffinity::Error => e
      say e.message, :red
      exit 1
    end

    desc "remove FILE...", "Removes a file from the upload queue"
    def remove(*files)
      if files.empty?
        say "You need to pass a file.", :red
        help :remove
        exit 1
      end

      queue.reload

      files_removed = queue.remove(*files)
      files_removed.each do |file|
        say "removed #{file.inspect}", :green
      end
    rescue Furaffinity::Error => e
      say e.message, :red
      exit 1
    end

    desc "clean", "Remove uploaded files"
    def clean
      queue.reload
      queue.clean
      say "Removed uploaded files", :green
    rescue Furaffinity::Error => e
      say e.message, :red
      exit 1
    end

    desc "reorder", "Open an editor to rearrange the queue"
    def reorder
      queue.reload
      queue.reorder unless queue.queue.empty?

      invoke :status
    end

    desc "status", "Print the current status of the queue"
    def status
      queue.reload

      if queue.queue.empty?
        say "Nothing is in the queue yet, use `#{File.basename $0} queue add ...` to add files.", :yellow

        print_uploaded_files
        return
      end

      say "Enqueued files:"
      queue_table = [["Position", "File name", "Title", "Rating"], :separator]
      queue.queue.each_with_index do |file_name, idx|
        file_info = queue.file_info.fetch(file_name)
        queue_table << [idx + 1, file_name, file_info[:title], file_info[:rating]]
      end
      print_table queue_table, borders: true

      print_uploaded_files

    rescue Furaffinity::Error => e
      say e.message, :red
      exit 1
    end

    desc "upload", "Upload all submissions in the queue."
    option :wait_time, type: :numeric, desc: "Seconds to wait between each upload.", default: 60
    def upload
      if options[:wait_time] < 30
        say "--wait-time must be at least 30", :red
        exit 1
      end

      queue.reload
      queue.upload(options[:wait_time])
      say "Submissions uploaded.", :green
    rescue Furaffinity::Error => e
      say e.message, :red
      exit 1
    end

    private

    def queue(dir = Dir.pwd)
      @queue ||= begin
        set_log_level(options)
        config = config_for(options)
        Queue.new(config.new_client, dir)
      end
    end

    def print_uploaded_files
      uploaded_files = queue.uploaded_files
      unless uploaded_files.empty?
        say
        say "Uploaded files (will be removed when you run `#{File.basename $0} queue clean`):"
        uploaded_table = [["File name", "Title", "Submission URL"], :separator]
        uploaded_files.each do |file_name, upload_status|
          file_info = queue.file_info.fetch(file_name)
          uploaded_table << [file_name, file_info[:title], upload_status[:url]]
        end
        print_table uploaded_table, borders: true
      end
    end
  end
end
