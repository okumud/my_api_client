# frozen_string_literal: true

module MyApiClient
  # Description of Request
  module Request
    # Description of #_request
    #
    # @param http_method [Symbol] describe_http_method_here
    # @param pathname [String] describe_pathname_here
    # @param headers [Hash, nil] describe_headers_here
    # @param query [Hash, nil] describe_query_here
    # @param body [Hash, nil] describe_body_here
    # @param logger [::Logger] describe_logger_here
    # @return [Sawyer::Resource] description_of_returned_object
    # rubocop:disable Metrics/ParameterLists
    def _request(http_method, pathname, headers, query, body, logger)
      processed_path = [common_path, pathname].join('/').gsub('//', '/')
      request_params = Params::Request.new(http_method, processed_path, headers, query, body)
      agent # Initializes for faraday
      request_logger = Logger.new(logger, faraday, http_method, processed_path)
      call(:_execute, request_params, request_logger)
    end
    # rubocop:enable Metrics/ParameterLists

    private

    # Description of #agent
    #
    # @return [Sawyer::Agent] description_of_returned_object
    def agent
      @agent ||= Sawyer::Agent.new(schema_and_hostname, faraday: faraday)
    end

    # Description of #faraday
    #
    # @return [Faraday::Connection] description_of_returned_object
    def faraday
      @faraday ||=
        Faraday.new(
          nil,
          request: {
            timeout: (http_read_timeout if respond_to?(:http_read_timeout)),
            open_timeout: (http_open_timeout if respond_to?(:http_open_timeout)),
          }.compact
        )
    end

    # Description of #_execute
    #
    # @param request_params [MyApiClient::Params::Request] describe_request_params_here
    # @param request_logger [MyApiClient::Logger] describe_request_logger_here
    # @return [Sawyer::Resource] description_of_returned_object
    # @raise [MyApiClient::Error]
    def _execute(request_params, request_logger)
      request_logger.info('Start')
      response = agent.call(*request_params.to_sawyer_args)
      request_logger.info("Duration #{response.timing} sec")
      params = Params::Params.new(request_params, response)
      _verify(params, request_logger)
    rescue *NETWORK_ERRORS => e
      params ||= Params::Params.new(request_params, nil)
      request_logger.error("Network Error (#{e.message})")
      raise MyApiClient::NetworkError.new(params, e)
    rescue MyApiClient::Error => e
      request_logger.warn("Failure (#{response.status})")
      raise e
    else
      request_logger.info("Success (#{response.status})")
      response.data
    end

    # Description of #_verify
    #
    # @param params [MyApiClient::Params::Params] describe_params_here
    # @param request_logger [MyApiClient::Logger] describe_request_logger_here
    # @return [nil] description_of_returned_object
    # @raise [MyApiClient::Error]
    def _verify(params, request_logger)
      case error_handler = error_handling(params.response)
      when Proc
        error_handler.call(params, request_logger)
      when Symbol
        send(error_handler, params, request_logger)
      end
    end
  end
end
