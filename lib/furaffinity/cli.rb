# frozen_string_literal: true

require "json"
require "thor"

module Furaffinity
  class Cli < Thor
    include CliBase

    class_option :log_level,
      type:    :string,
      desc:    "Log level to use",
      default: "info"

    class_option :config,
      type:    :string,
      desc:    "Path to the config",
      default: File.join(Dir.home, ".farc")

    desc "auth A_COOKIE B_COOKIE", "Store authentication info for FurAffinity"
    def auth(a_cookie, b_cookie)
      set_log_level(options)
      config = config_for(options)
      config.set!(a: a_cookie, b: b_cookie)
      say "Authentication info stored.", :green
    end

    desc "notifications", "Get the current notification counters as JSON"
    def notifications
      set_log_level(options)
      config = config_for(options)
      client = config.new_client

      puts JSON.pretty_generate client.notifications
    end

    desc "upload FILE_PATH", "Upload a new submission"
    option :type,
      type:    :string,
      desc:    "Submission type.  One of: #{Furaffinity::Client::SUBMISSION_TYPES.join(", ")}",
      default: "submission"
    option :title,
      type:     :string,
      desc:     "Submission title.",
      required: true
    option :description,
      type:     :string,
      desc:     "Submission description.",
      required: true
    option :rating,
      type:     :string,
      desc:     "Submission rating.  One of: #{Furaffinity::Client::RATING_MAP.keys.join(", ")}",
      required: true
    option :lock_comments,
      type:    :boolean,
      desc:    "Disable comments on this submission.",
      default: false
    option :scrap,
      type:    :boolean,
      desc:    "Place this upload to your scraps.",
      default: false
    option :keywords,
      type:    :string,
      desc:    "Keywords, separated by spaces.",
      default: ""
    option :create_folder_name,
      type:    :string,
      desc:    "Create a new folder and place this submission into it.",
      default: ""
    def upload(file_path)
      set_log_level(options)
      config = config_for(options)
      client = config.new_client

      upload_options = options.slice(
        *client
          .method(:upload)
          .parameters
          .select { |(type, name)| %i[keyreq key].include?(type) }
          .map(&:last)
      ).transform_keys(&:to_sym)
      url = client.upload(File.new(file_path), **upload_options)
      say "Submission uploaded!  #{url}", :green
    end

    desc "queue SUBCOMMAND ...ARGS", "Manage an upload queue"
    long_desc <<~LONG_DESC, wrap: false
      `#{basename} queue` manages an upload queue.

      It behaves somewhat like `git`, where you have to initialise a designated
      directory first for it to use as a queue.

      An example workflow with `#{basename} queue` would look like:

          # set your preferred editor in ENV
          export EDITOR=vi

          # initialise queue directory
          #{basename} queue init my_queue
          cd my_queue

          # copy files to upload into the queue directory
          cp ~/Pictures/pic*.png .

          # add files, an editor will open up for each file to fill in the details
          #{basename} queue add pic1.png
          #{basename} queue add pic2.png pic3.png

          # see the status of the queue
          #{basename} queue status

          # use your preferred editor to change the submission information afterwards
          vi pic2.png.info.yml

          # open up an editor to rearrange the queue order
          #{basename} queue reorder

          # upload the entire queue
          #{basename} queue upload

          # once everything's uploaded you can remove the already uploaded pics
          #{basename} queue clean
    LONG_DESC
    subcommand "queue", CliQueue

    map %w[--version -v] => :__print_version

    desc "--version, -v", "Print the version"
    def __print_version = puts "furaffinity-cli/#{VERSION}"
  end
end
