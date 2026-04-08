require "rails_helper"

RSpec.describe "GenerationRequests", type: :request do
  describe "GET /generation_requests/new" do
    it "shows form" do
      get new_generation_request_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Генерация описания задачи")
      expect(response.body).to include("Состояние: EMPTY")
    end
  end

  describe "POST /generation_requests" do
    it "returns SUCCESS JSON for valid params" do
      allow(Generation::AiClient).to receive(:call).and_return(
        Generation::AiClient::Result.new(
          success: true,
          task_description: "Warhammer 40K: выстрой строй. Реши через сортировка",
          error_code: nil
        )
      )

      post generation_requests_path, params: {
        generation_request: { skill: " сортировка ", topic: " <b>Warhammer 40K</b> " }
      }

      expect(response).to have_http_status(:ok)

      body = json_response
      expect(body["state"]).to eq("SUCCESS")
      expect(body["task_description"]).to eq("Warhammer 40K: выстрой строй. Реши через сортировка")
      expect(body["generation_request_id"]).to be_present

      request = GenerationRequest.find(body["generation_request_id"])
      expect(request.status).to eq("SUCCESS")
      expect(request.skill).to eq("сортировка")
      expect(request.topic).to eq("Warhammer 40K")
    end

    it "returns ERROR E201 without generation_request_id and without DB write" do
      expect(Generation::AiClient).not_to receive(:call)

      expect do
        post generation_requests_path, params: {
          generation_request: { skill: "   ", topic: "Ruby" }
        }
      end.not_to change(GenerationRequest, :count)

      expect(response).to have_http_status(:unprocessable_content)

      body = json_response
      expect(body).to eq({
        "state" => "ERROR",
        "error_code" => "E201"
      })
    end

    it "returns ERROR E203 without generation_request_id and without DB write" do
      expect(Generation::AiClient).not_to receive(:call)

      expect do
        post generation_requests_path, params: {
          generation_request: { skill: "Ruby", topic: "a" * 101 }
        }
      end.not_to change(GenerationRequest, :count)

      expect(response).to have_http_status(:unprocessable_content)

      body = json_response
      expect(body).to eq({
        "state" => "ERROR",
        "error_code" => "E203"
      })
    end

    it "returns ERROR E204 with generation_request_id for retryable generation errors" do
      allow(Generation::AiClient).to receive(:call).and_return(
        Generation::AiClient::Result.new(success: false, task_description: nil, error_code: "E204")
      )

      expect do
        post generation_requests_path, params: {
          generation_request: { skill: "Ruby", topic: "Warhammer" }
        }
      end.to change(GenerationRequest, :count).by(1)

      expect(response).to have_http_status(:unprocessable_content)

      body = json_response
      expect(body["state"]).to eq("ERROR")
      expect(body["error_code"]).to eq("E204")
      expect(body["generation_request_id"]).to be_present

      request = GenerationRequest.find(body["generation_request_id"])
      expect(request.status).to eq("ERROR")
      expect(request.error_code).to eq("E204")
    end
  end

  def json_response
    JSON.parse(response.body)
  end
end
