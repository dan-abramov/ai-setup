require "rails_helper"

RSpec.describe "GenerationRequests", type: :request do
  describe "GET /generation_requests/new" do
    it "shows form" do
      get new_generation_request_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Навык")
      expect(response.body).to include("Тема")
    end
  end

  describe "POST /generation_requests" do
    it "redirects to the next step for valid params" do
      post generation_requests_path, params: {
        generation_request: { skill: " Сортировка ", topic: " <b>Warhammer 40K</b> " }
      }

      expect(response).to redirect_to(generation_flow_path(skill: "Сортировка", topic: "Warhammer 40K"))
      expect(GenerationRequest.count).to eq(1)
      expect(GenerationRequest.last.skill).to eq("Сортировка")
      expect(GenerationRequest.last.topic).to eq("Warhammer 40K")
    end

    it "does not redirect and renders validation codes for invalid params" do
      post generation_requests_path, params: {
        generation_request: { skill: "!!!", topic: "Warhammer 40K" }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("E003")
      expect(response.body).to include("value=\"!!!\"")
      expect(response.body).to include("value=\"Warhammer 40K\"")
      expect(GenerationRequest.count).to eq(0)
    end

    it "renders general E007 alert for server errors" do
      result = GenerationRequests::SubmitService::Result.new(
        status: :server_error,
        generation_request: GenerationRequest.new(skill: "Ruby", topic: "Topic"),
        error_code: "E007"
      )
      allow(GenerationRequests::SubmitService).to receive(:call).and_return(result)

      post generation_requests_path, params: {
        generation_request: { skill: "Ruby", topic: "Topic" }
      }

      expect(response).to have_http_status(:internal_server_error)
      expect(response.body).to include("E007")
      expect(response.body).to include("Внутренняя ошибка сервера")
    end
  end
end
