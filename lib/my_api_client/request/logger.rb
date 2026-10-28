# frozen_string_literal: true

module MyApiClient
  module Request
    # Description of Logger
    class Logger
      attr_reader :logger, :method, :uri

      LOG_LEVEL = %i[debug info warn error fatal].freeze

      DEFAULT_FORMATTER = lambda { |method, uri, message|
        "API request `#{method} #{uri}`: \"#{message}\""
      }

      # Description of #initialize
      #
      # @param logger [::Logger] describe_logger_here
      # @param method [String] HTTP method
      # @param uri [URI] Target URI
      # @param formatter [#call]
      #   Receives the HTTP method, target URI and message, and returns the formatted log message.
      def initialize(logger, method, uri, formatter: DEFAULT_FORMATTER)
        @logger = logger
        @method = method.to_s.upcase
        @uri = uri
        @formatter = formatter
      end

      LOG_LEVEL.each do |level|
        class_eval <<~METHOD, __FILE__, __LINE__ + 1
          def #{level}(message)
            logger.#{level}(format(message))
          end
        METHOD
      end

      private

      attr_reader :formatter

      def format(message)
        formatter.call(method, uri, message)
      end
    end
  end
end
