# frozen_string_literal: true

module Furaffinity
  class QueueHook
    include SemanticLogger::Loggable

    class HookRunner
      include SemanticLogger::Loggable

      attr_reader :client, :file_info, :submission_info

      def initialize(client, file_info, file_name)
        @client = client
        @file_info = file_info
        @submission_info = file_info.fetch(file_name)
      end

      def submission_url(submission_id) = "https://www.furaffinity.net/view/#{submission_id}/"

      def link_to(url_or_submission, text)
        url = case url_or_submission
              in { id: }
                submission_url(id)
              else
                if url_or_submission.is_a?(Hash)
                  logger.warn { "passed hash does not have an ID, probably not uploaded yet?  hash keys: #{url_or_submission.keys.inspect}" }
                end
                url_or_submission.to_s
              end

        "[url=#{url}]#{text}[/url]"
      end
    end

    attr_reader :client, :file_info

    def initialize(client, file_info)
      @client = client
      @file_info = file_info.each_with_object({}) do |(file_name, info), h|
        # Hash#except duplicates the hash, which is good here as we don't want
        # to modify the queue.
        # exclude after_upload as it's not needed, and create_folder_name and
        # type is only relevant when initially uploading the submission.
        h[file_name] = info.except(:create_folder_name, :after_upload, :type)
      end
    end

    def update_ids(upload_status)
      logger.trace { "Updating file info ids" }
      upload_status.each do |file_name, status|
        next unless status[:uploaded]

        @file_info[file_name][:id] = status[:url].match(%{/view/(?<id>[^/]+)})[:id]
      end
    end

    def run_hook(file_name, code)
      logger.debug { "Running hook" }
      logger.trace { "Hook code:\n#{code}" }
      HookRunner
        .new(client, file_info, file_name)
        .instance_eval(code, File.join(Dir.pwd, "#{file_name}.info.yml"), 0)
    end
  end
end
