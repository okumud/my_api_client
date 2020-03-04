# frozen_string_literal: true

require './example/api_clients/my_status_api_client'

RSpec.describe 'Integration test with My Status API' do
  before do
    WebMock.disable_net_connect!(allow: /#{ENV['MY_API_ENDPOINT']}*/)
  end

  after do
    WebMock.disable_net_connect!
  end

  let(:api_client) { MyStatusApiClient.new }

  describe 'GET status/:status' do
    context 'with status code: 200' do
      it 'returns specified ID and message' do
        response = api_client.get_status(status: 200)
        expect(response.message).to eq 'You requested status code: 200'
      end
    end

    context 'with status code: 400' do
      it do
        expect { api_client.get_status(status: 400) }
          .to raise_error(MyErrors::BadRequest)
      end
    end

    context 'with status code: 401' do
      it do
        expect { api_client.get_status(status: 401) }
          .to raise_error(MyErrors::Unauthorized)
      end
    end

    context 'with status code: 403' do
      it do
        expect { api_client.get_status(status: 403) }
          .to raise_error(MyErrors::Forbidden)
      end
    end
  end
end
