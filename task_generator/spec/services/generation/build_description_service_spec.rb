require "rails_helper"

RSpec.describe Generation::BuildDescriptionService, type: :service do
  let(:ai_client) { class_double(Generation::AiClient) }

  def service_call(params)
    described_class.new(params, ai_client:).call
  end

  describe "#call" do
    it "persists SUCCESS for valid input and generated description" do
      allow(ai_client).to receive(:call).and_return(
        Generation::AiClient::Result.new(
          success: true,
          task_description: "Warhammer 40K: перегруппируйся. Реши через сортировка пузырьком",
          error_code: nil
        )
      )

      result = nil

      expect do
        result = service_call(skill: " <b>сортировка пузырьком</b> ", topic: " <i>Warhammer 40K</i> ")
      end.to change(GenerationRequest, :count).by(1)

      expect(result).to be_success
      expect(result.error_code).to be_nil
      expect(result.task_description).to include("Реши через")
      expect(ai_client).to have_received(:call).with(skill: "сортировка пузырьком", topic: "Warhammer 40K")

      request = result.generation_request
      expect(request).to be_persisted
      expect(request.status).to eq(GenerationRequest::STATUS_SUCCESS)
      expect(request.error_code).to be_nil
      expect(request.task_description).to eq(result.task_description)
      expect(request.latency_ms).to be_a(Integer)
    end

    it "returns E201 and does not create record for blank skill" do
      expect do
        result = service_call(skill: " ", topic: "Ruby")

        expect(result).not_to be_success
        expect(result.error_code).to eq("E201")
        expect(result.generation_request).to be_nil
      end.not_to change(GenerationRequest, :count)
    end

    it "returns E203 and does not create record for too long topic" do
      expect do
        result = service_call(skill: "Ruby", topic: "a" * 101)

        expect(result).not_to be_success
        expect(result.error_code).to eq("E203")
        expect(result.generation_request).to be_nil
      end.not_to change(GenerationRequest, :count)
    end

    it "persists ERROR E204 when AI call times out" do
      allow(ai_client).to receive(:call).and_return(
        Generation::AiClient::Result.new(success: false, task_description: nil, error_code: "E204")
      )

      result = service_call(skill: "Ruby", topic: "Warhammer")

      expect(result).not_to be_success
      expect(result.error_code).to eq("E204")
      expect(result.generation_request).to be_persisted
      expect(result.generation_request.status).to eq(GenerationRequest::STATUS_ERROR)
      expect(result.generation_request.error_code).to eq("E204")
      expect(result.generation_request.task_description).to be_nil
      expect(result.generation_request.latency_ms).to be_a(Integer)
    end

    it "persists SUCCESS when AI response is blank after normalization (validator stub)" do
      allow(ai_client).to receive(:call).and_return(
        Generation::AiClient::Result.new(
          success: true,
          task_description: " <b> </b> ",
          error_code: nil
        )
      )

      result = service_call(skill: "сортировка пузырьком", topic: "Warhammer")

      expect(result).to be_success
      expect(result.error_code).to be_nil
      expect(result.generation_request).to be_persisted
      expect(result.generation_request.status).to eq(GenerationRequest::STATUS_SUCCESS)
      expect(result.generation_request.error_code).to be_nil
      expect(result.generation_request.task_description).to eq("")
    end

    it "persists SUCCESS for too long AI response (validator stub)" do
      allow(ai_client).to receive(:call).and_return(
        Generation::AiClient::Result.new(
          success: true,
          task_description: "a" * 151,
          error_code: nil
        )
      )

      result = service_call(skill: "сортировка пузырьком", topic: "Warhammer")

      expect(result).to be_success
      expect(result.error_code).to be_nil
      expect(result.generation_request).to be_persisted
      expect(result.generation_request.status).to eq(GenerationRequest::STATUS_SUCCESS)
      expect(result.generation_request.error_code).to be_nil
      expect(result.generation_request.task_description).to eq("a" * 151)
    end

    it "persists SUCCESS when AI response does not include topic (validator stub)" do
      allow(ai_client).to receive(:call).and_return(
        Generation::AiClient::Result.new(
          success: true,
          task_description: "Упорядочь массив. Реши через сортировка пузырьком",
          error_code: nil
        )
      )

      result = service_call(skill: "сортировка пузырьком", topic: "Warhammer")

      expect(result).to be_success
      expect(result.error_code).to be_nil
      expect(result.generation_request).to be_persisted
      expect(result.generation_request.status).to eq(GenerationRequest::STATUS_SUCCESS)
      expect(result.generation_request.error_code).to be_nil
      expect(result.generation_request.task_description).to eq("Упорядочь массив. Реши через сортировка пузырьком")
    end

    it "persists SUCCESS when AI response does not include skill (validator stub)" do
      allow(ai_client).to receive(:call).and_return(
        Generation::AiClient::Result.new(
          success: true,
          task_description: "Warhammer: упорядочь массив. Реши через бинарный поиск",
          error_code: nil
        )
      )

      result = service_call(skill: "сортировка пузырьком", topic: "Warhammer")

      expect(result).to be_success
      expect(result.error_code).to be_nil
      expect(result.generation_request).to be_persisted
      expect(result.generation_request.status).to eq(GenerationRequest::STATUS_SUCCESS)
      expect(result.generation_request.error_code).to be_nil
      expect(result.generation_request.task_description).to eq("Warhammer: упорядочь массив. Реши через бинарный поиск")
    end

    it "maps unexpected internal exception to E205" do
      allow(ai_client).to receive(:call).and_raise(StandardError, "boom")

      result = service_call(skill: "Ruby", topic: "Warhammer")

      expect(result).not_to be_success
      expect(result.error_code).to eq("E205")
      expect(result.generation_request).to be_persisted
      expect(result.generation_request.status).to eq(GenerationRequest::STATUS_ERROR)
      expect(result.generation_request.error_code).to eq("E205")
    end
  end
end
