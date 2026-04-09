require "rails_helper"

RSpec.describe Generation::AiClient, type: :service do
  let(:config) do
    ActiveSupport::OrderedOptions.new.tap do |options|
      options.openrouter_api_url = "https://openrouter.ai/api/v1/chat/completions"
      options.openrouter_api_key = "test-key"
      options.openrouter_timeout_seconds = 1
      options.openrouter_primary_model = "qwen/qwen2.5-7b-instruct:free"
      options.openrouter_fallback_model = "meta-llama/llama-3.1-8b-instruct:free"
    end
  end

  let(:client) { described_class.new(skill: "Сортировка", topic: "Warhammer 40K", config:) }
  let(:http) { instance_double(Net::HTTP) }

  before do
    allow(Net::HTTP).to receive(:start).and_yield(http)
  end

  describe "#call" do
    it "returns description from primary model" do
      called_models = []
      allow(http).to receive(:request) do |request|
        called_models << JSON.parse(request.body)["model"]
        success_response("Warhammer 40K: наведи порядок. Реши через сортировка")
      end

      result = client.call

      expect(result).to be_success
      expect(result.task_description).to include("Реши через")
      expect(called_models).to eq([config.openrouter_primary_model])
    end

    it "uses fallback model when primary fails" do
      called_models = []
      responses = [provider_error_response, success_response("Warhammer 40K: перегруппируйся. Реши через сортировка")]

      allow(http).to receive(:request) do |request|
        called_models << JSON.parse(request.body)["model"]
        responses.shift
      end

      result = client.call

      expect(result).to be_success
      expect(called_models).to eq([
        config.openrouter_primary_model,
        config.openrouter_fallback_model
      ])
    end

    it "returns E204 on timeout" do
      allow(http).to receive(:request).and_raise(Net::ReadTimeout)

      result = client.call

      expect(result).not_to be_success
      expect(result.error_code).to eq("E204")
      expect(http).to have_received(:request).once
    end

    it "returns E205 when API key is missing" do
      config.openrouter_api_key = ""

      result = client.call

      expect(result).not_to be_success
      expect(result.error_code).to eq("E205")
      expect(Net::HTTP).not_to have_received(:start)
    end

    it "returns E205 when both models fail" do
      allow(http).to receive(:request).and_return(provider_error_response, provider_error_response)

      result = client.call

      expect(result).not_to be_success
      expect(result.error_code).to eq("E205")
    end
  end

  def success_response(content)
    response = Net::HTTPOK.new("1.1", "200", "OK")
    payload = {
      choices: [
        {
          message: {
            content:
          }
        }
      ]
    }

    allow(response).to receive(:body).and_return(payload.to_json)
    response
  end

  def provider_error_response
    response = Net::HTTPBadRequest.new("1.1", "400", "Bad Request")
    allow(response).to receive(:body).and_return("{}")
    response
  end
end
