# frozen_string_literal: true

module MyApiClient
  # Test helper module for RSpec
  module Stub
    # Stubs all instance of arbitrary MyApiClient class.
    # And returns a stubbed arbitrary MyApiClient instance.
    #
    # @param klass [Class]
    #   Stubbing target class.
    # @param actions_and_options [Hash]
    #   Stubbing target method and options
    # @example
    #   stub_api_client_all(
    #     ExampleApiClient,
    #     get_user: { response: { id: 1 } },               # Returns an arbitrary response.
    #     post_users: { id: 1 },                           # You can ommit `response` keyword.
    #     patch_user: ->(params) { { id: params[:id] } },  # Returns calculated result as response.
    #     delete_user: { raise: MyApiClient::ClientError } # Raises an arbitrary error.
    #   )
    #   response = ExampleApiClient.new.get_user(id: 123)
    #   response.id # => 1
    # @return [InstanceDouble]
    #   Returns a spy object of the stubbed ApiClient.
    def stub_api_client_all(klass, **actions_and_options)
      instance = stub_api_client(klass, actions_and_options)
      allow(klass).to receive(:new).and_return(instance)
      instance
    end

    # Returns a stubbed arbitrary MyApiClient instance.
    #
    # @param klass [Class]
    #   Stubbing target class.
    # @param actions_and_options [Hash]
    #   Stubbing target method and options
    # @example
    #   api_client = stub_api_client(
    #     ExampleApiClient,
    #     get_user: { response: { id: 1 } },               # Returns an arbitrary response.
    #     post_users: { id: 1 },                           # You can ommit `response` keyword.
    #     patch_user: ->(params) { { id: params[:id] } },  # Returns calculated result as response.
    #     delete_user: { raise: MyApiClient::ClientError } # Raises an arbitrary error.
    #   )
    #   response = api_client.get_user(id: 123)
    #   response.id # => 1
    # @return [InstanceDouble]
    #   Returns a spy object of the stubbed ApiClient.
    def stub_api_client(klass, **actions_and_options)
      instance = instance_double(klass)
      actions_and_options.each { |action, options| stubbing(instance, action, options) }
      instance
    end

    private

    # rubocop:disable Metrics/AbcSize
    def stubbing(instance, action, options)
      case options
      when Proc
        allow(instance).to receive(action) { |*request| stub_as_sawyer(options.call(*request)) }
      when Hash
        if options[:raise].present?
          allow(instance).to receive(action).and_raise(process_raise_option(options[:raise]))
        elsif options[:response]
          allow(instance).to receive(action).and_return(stub_as_sawyer(options[:response]))
        else
          allow(instance).to receive(action).and_return(stub_as_sawyer(options))
        end
      else
        allow(instance).to receive(action).and_return(stub_as_sawyer(options))
      end
    end
    # rubocop:enable Metrics/AbcSize

    # Provides a shorthand for `raise` option.
    # `MyApiClient::Error` requires `MyApiClient::Params::Params` instance on
    # initialize, but it makes trubolesome. `MyApiClient::NetworkError` is more.
    # If given a error instance, it will return raw value without processing.
    #
    # @param exception [Clsas, MyApiClient::Error] Processing target.
    # @return [MyApiClient::Error] Processed exception.
    # @raise [RuntimeError] Unsupported error class was set.
    def process_raise_option(exception)
      case exception
      when Class
        params = instance_double(MyApiClient::Params::Params, metadata: {})
        if exception == MyApiClient::NetworkError
          exception.new(params, Net::OpenTimeout.new)
        else
          exception.new(params)
        end
      when MyApiClient::Error
        exception
      else
        raise "Unsupported error class was set: #{exception.inspect}"
      end
    end

    def stub_as_sawyer(params)
      case params
      when Hash  then Sawyer::Resource.new(agent, params)
      when Array then params.map { |hash| stub_as_sawyer(hash) }
      when nil   then nil
      else params
      end
    end

    def agent
      instance_double(Sawyer::Agent).tap do |agent|
        allow(agent).to receive(:parse_links) do |data|
          data ||= {}
          links = data.delete(:_links)
          [data, links]
        end
      end
    end
  end
end
