require "rails_helper"

RSpec.describe "GenerationFlow", type: :request do
  describe "GET /generation_flow/:id" do
    it "allows transition only for SUCCESS requests" do
      request_record = create(
        :generation_request,
        status: GenerationRequest::STATUS_SUCCESS,
        task_description: "Warhammer 40K: выстрой строй. Реши через сортировка"
      )

      get generation_flow_path(request_record.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Warhammer 40K: выстрой строй. Реши через сортировка")
    end

    it "redirects to form for ERROR requests" do
      request_record = create(:generation_request, :error, error_code: "E204")

      get generation_flow_path(request_record.id)

      expect(response).to redirect_to(new_generation_request_path)
      follow_redirect!
      expect(response.body).to include("Переход к решению доступен только после успешной генерации.")
    end
  end

  describe "GET /generation_flow/metrics" do
    before do
      create_list(
        190,
        :generation_request,
        status: GenerationRequest::STATUS_SUCCESS,
        latency_ms: 500,
        error_code: nil
      )

      create_list(
        10,
        :generation_request,
        :error,
        latency_ms: 1200,
        error_code: "E205"
      )
    end

    it "returns p95 and success rate for last 200 valid requests" do
      get "/generation_flow/metrics"

      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)

      expect(body["window_size"]).to eq(200)
      expect(body["p95_latency_ms"]).to eq(500)
      expect(body["success_rate"]).to eq(95.0)
      expect(body.dig("meets_slo", "p95")).to eq(true)
      expect(body.dig("meets_slo", "success_rate")).to eq(true)
    end
  end
end
