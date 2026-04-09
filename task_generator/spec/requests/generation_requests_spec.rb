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
    it "returns SUCCESS with task_id/task_path and creates one Task (AC-01)" do
      allow(Generation::AiClient).to receive(:call).and_return(
        Generation::AiClient::Result.new(
          success: true,
          task_description: "Warhammer 40K: выстрой строй. Реши через сортировка",
          error_code: nil
        )
      )

      expect do
        post generation_requests_path, params: {
          generation_request: { skill: " сортировка ", topic: " <b>Warhammer 40K</b> " }
        }
      end.to change(GenerationRequest, :count).by(1).and change(Task, :count).by(1)

      expect(response).to have_http_status(:ok)

      body = json_response
      expect(body["state"]).to eq("SUCCESS")
      expect(body["task_id"]).to be_present
      expect(body["task_path"]).to be_present
      expect(body).not_to have_key("task_description")
      expect(body).not_to have_key("generation_request_id")

      task = Task.find(body["task_id"])
      expect(task.description).to eq("Warhammer 40K: выстрой строй. Реши через сортировка")
      expect(body["task_path"]).to eq(task_path(task))

      request = GenerationRequest.order(:id).last
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

    it "returns ERROR E204 with generation_request_id and without Task creation" do
      allow(Generation::AiClient).to receive(:call).and_return(
        Generation::AiClient::Result.new(success: false, task_description: nil, error_code: "E204")
      )

      expect do
        post generation_requests_path, params: {
          generation_request: { skill: "Ruby", topic: "Warhammer" }
        }
      end.to change(GenerationRequest, :count).by(1).and change(Task, :count).by(0)

      expect(response).to have_http_status(:unprocessable_content)

      body = json_response
      expect(body["state"]).to eq("ERROR")
      expect(body["error_code"]).to eq("E204")
      expect(body["generation_request_id"]).to be_present

      request = GenerationRequest.find(body["generation_request_id"])
      expect(request.status).to eq("ERROR")
      expect(request.error_code).to eq("E204")
    end

    it "returns E301 when validator stub passes blank description but Task validation fails" do
      allow(Generation::AiClient).to receive(:call).and_return(
        Generation::AiClient::Result.new(success: true, task_description: " <b> </b> ", error_code: nil)
      )

      expect do
        post generation_requests_path, params: {
          generation_request: { skill: "сортировка", topic: "Warhammer" }
        }
      end.to change(GenerationRequest, :count).by(1).and change(Task, :count).by(0)

      expect(response).to have_http_status(:unprocessable_content)
      body = json_response
      expect(body["state"]).to eq("ERROR")
      expect(body["error_code"]).to eq("E301")
      expect(body["generation_request_id"]).to be_present
    end

    it "returns SUCCESS for description that previously failed E208/E209 checks" do
      allow(Generation::AiClient).to receive(:call).and_return(
        Generation::AiClient::Result.new(
          success: true,
          task_description: "Warhammer: упорядочь строй. Реши через бинарный поиск",
          error_code: nil
        )
      )

      expect do
        post generation_requests_path, params: {
          generation_request: { skill: "сортировка", topic: "Warhammer" }
        }
      end.to change(GenerationRequest, :count).by(1).and change(Task, :count).by(1)

      expect(response).to have_http_status(:ok)
      body = json_response
      expect(body["state"]).to eq("SUCCESS")
      expect(body["task_id"]).to be_present
      expect(body["task_path"]).to eq(task_path(body["task_id"]))
    end

    it "returns ERROR E301 with generation_request_id when Task creation fails (AC-03)" do
      allow(Generation::AiClient).to receive(:call).and_return(
        Generation::AiClient::Result.new(
          success: true,
          task_description: "Warhammer 40K: выстрой строй. Реши через сортировка",
          error_code: nil
        )
      )
      allow(Task).to receive(:new).and_return(instance_double(Task, save: false))

      expect do
        post generation_requests_path, params: {
          generation_request: { skill: "сортировка", topic: "Warhammer 40K" }
        }
      end.to change(GenerationRequest, :count).by(1).and change(Task, :count).by(0)

      expect(response).to have_http_status(:unprocessable_content)
      body = json_response
      expect(body["state"]).to eq("ERROR")
      expect(body["error_code"]).to eq("E301")
      expect(body["generation_request_id"]).to be_present
    end
  end

  def json_response
    JSON.parse(response.body)
  end
end
