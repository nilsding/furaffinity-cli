# frozen_string_literal: true

require "httpx"
require "nokogiri"

module Furaffinity
  class Client
    include SemanticLogger::Loggable

    BASE_URL = "https://www.furaffinity.net"

    # @param a [String] value of the `a` cookie
    # @param b [String] value of the `b` cookie
    def initialize(a:, b:)
      raise Error.new("a needs to be a non-zero string") unless a.is_a?(String) || a.empty?
      raise Error.new("b needs to be a non-zero string") unless b.is_a?(String) || b.empty?

      @auth_cookies = { "a" => a, "b" => b }
    end

    def http_client
      HTTPX
        .plugin(:cookies)
        .plugin(:stream)
        # .plugin(:follow_redirects)
        .with(headers: { "user-agent" => "furaffinity/#{Furaffinity::VERSION} (Ruby)" })
        .with_cookies(@auth_cookies)
    end

    def get(path, client: nil)
      client ||= http_client
      url = File.join(BASE_URL, path)
      logger.measure_trace("GET #{url}") do
        client.get(url)
      end
    end

    def post(path, form: {}, client: nil)
      client ||= http_client
      url = File.join(BASE_URL, path)
      logger.measure_trace("POST #{url}", { form: }) do
        client.post(url, form:)
      end
    end

    NOTIFICATIONS_MAP = {
      "submission"    => :submissions,
      "watch"         => :watches,
      "comment"       => :comments,
      "favorite"      => :favourites,
      "journal"       => :journals,
      "unread"        => :notes,
      "troubleticket" => :trouble_tickets,
    }

    def notifications
      get("/")
        .then(&method(:parse_response))
        .css("a.notification-container")
        .map { _1.attr(:title) }
        .uniq
        .each_with_object({}) do |item, h|
          count, type, *_rest = item.split(" ")
          count = count.tr(",", "").strip.to_i
          h[NOTIFICATIONS_MAP.fetch(type.downcase.strip)] = count
        end
    end

    SUBMISSION_TYPES = %i[submission story poetry music].freeze
    RATING_MAP = {
      general: 0,
      mature:  2,
      adult:   1,
    }.freeze

    def fake_upload(file, title:, rating:, description:, keywords:, create_folder_name: "", lock_comments: false, scrap: false, type: :submission)
      validate_args!(type:, rating:) => { type:, rating: }

      raise "not a file" unless file.is_a?(File)
      params = { MAX_FILE_SIZE: "10485760" }
      raise ArgumentError.new("file size of #{file.size} is greater than FA limit of #{params[:MAX_FILE_SIZE]}") if file.size > params[:MAX_FILE_SIZE].to_i
      "https://www.furaffinity.net/view/54328944/?upload-successful"
    end

    # @param file [File]
    def upload(file, title:, rating:, description:, keywords:, create_folder_name: "", lock_comments: false, scrap: false, type: :submission)
      validate_args!(type:, rating:) => { type:, rating: }

      client = http_client

      # step 1: get the required keys
      logger.trace "Extracting keys from upload form"
      response = get("/submit/", client:).then(&method(:parse_response))
      params = {
        submission_type: type,
        submission:      file,
        thumbnail:       {
          content_type: "application/octet-stream",
          filename: "",
          body: ""
        },
      }
      params.merge!(
        %w[MAX_FILE_SIZE key]
          .map { [_1.to_sym, response.css("form#myform input[name=#{_1}]").first.attr(:value)] }
          .to_h
      )
      raise ArgumentError.new("file size of #{file.size} is greater than FA limit of #{params[:MAX_FILE_SIZE]}") if file.size > params[:MAX_FILE_SIZE].to_i

      # step 2: upload the submission file
      logger.debug "Uploading submission..."
      upload_response = post("/submit/upload/", form: params, client:)
      # for some reason HTTPX performs a GET redirect with the params so we
      # can't use its plugin here
      # --> follow the redirect ourselves
      raise Error.new("expected a 302 response, got #{upload_response.status}") unless upload_response.status == 302

      redirect_location = upload_response.headers[:location]
      unless redirect_location == "/submit/finalize/"
        logger.warn "unexpected redirect target #{redirect_location.inspect}, expected \"/submit/finalize/\".  continuing regardless ..."
      end
      response = get(redirect_location, client:).then(&method(:parse_response))

      params = {
        key: response.css("form#myform input[name=key]").first.attr(:value),

        # category, "1" is "Visual Art -> All"
        cat: "1",
        # theme, "1" is "General Things -> All"
        atype: "1",
        # species, "1" is "Unspecified / Any"
        species: "1",
        # gender, "0" is "Any"
        gender: "0",

        rating:   RATING_MAP.fetch(rating),
        title:    title,
        message:  description,
        keywords: keywords,

        create_folder_name:,

        # finalize button :)
        finalize: "Finalize ",
      }
      params[:lock_comments] = "1" if lock_comments
      params[:scrap] = "1" if scrap

      logger.debug "Finalising submission..."
      finalize_response = post("/submit/finalize/", form: params, client:)
      if finalize_response.status == 302
        redirect_location = finalize_response.headers[:location]
        url = File.join(BASE_URL, redirect_location)
        logger.info "Uploaded! #{url}"
        return url
      else
        fa_error = parse_response(finalize_response).css(".redirect-message").text
        raise Error.new("FA returned: #{fa_error}")
      end
    end

    private

    def validate_args!(type: nil, rating:)
      if type
        type = type.to_sym
        raise ArgumentError.new("#{type.inspect} is not in #{SUBMISSION_TYPES.inspect}") unless SUBMISSION_TYPES.include?(type)
      end
      rating = rating.to_sym
      raise ArgumentError.new("#{rating.inspect} is not in #{RATING_MAP.keys.inspect}") unless RATING_MAP.include?(rating)

      { type:, rating: }
    end

    def parse_response(httpx_response)
      logger.measure_trace "Parsing response" do
        Nokogiri::HTML.parse(httpx_response)
      end
    end
  end
end
