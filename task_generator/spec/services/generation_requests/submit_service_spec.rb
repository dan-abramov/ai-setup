require "rails_helper"

RSpec.describe GenerationRequests::SubmitService, type: :service do
  let(:params) { { skill: "Ruby", topic: "Warhammer 40K" } }
  let(:build_service) { class_double(Generation::BuildDescriptionService) }

  def build_result(state:, generation_request:, task_description:, error_code:)
    Generation::BuildDescriptionService::Result.new(
      state:,
      generation_request:,
      task_description:,
      error_code:
    )
  end

  describe "#call" do
    subject(:service_call) do
      described_class.new(
        params,
        build_description_service: build_service,
        task_model:
      ).call
    end

    let(:task_model) { Task }

    it "creates Task for SUCCESS generation result (AC-01)" do
      generation_request = create(:generation_request, status: GenerationRequest::STATUS_SUCCESS)
      allow(build_service).to receive(:call).with(params).and_return(
        build_result(
          state: GenerationRequest::STATUS_SUCCESS,
          generation_request:,
          task_description: "Warhammer 40K: выстрой строй. Реши через сортировка",
          error_code: nil
        )
      )

      result = nil

      expect do
        result = service_call
      end.to change(Task, :count).by(1)

      expect(result).to be_success
      expect(result.error_code).to be_nil
      expect(result.task).to be_persisted
      expect(result.task.description).to eq("Warhammer 40K: выстрой строй. Реши через сортировка")
      expect(result.generation_request).to eq(generation_request)
    end

    it "passes through E201 without creating Task" do
      allow(build_service).to receive(:call).with(params).and_return(
        build_result(
          state: GenerationRequest::STATUS_ERROR,
          generation_request: nil,
          task_description: nil,
          error_code: "E201"
        )
      )

      expect do
        result = service_call

        expect(result).to be_error
        expect(result.error_code).to eq("E201")
        expect(result.generation_request).to be_nil
        expect(result.task).to be_nil
      end.not_to change(Task, :count)
    end

    it "passes through E208 with persisted generation_request and without Task creation" do
      generation_request = create(:generation_request, :error, error_code: "E208")
      allow(build_service).to receive(:call).with(params).and_return(
        build_result(
          state: GenerationRequest::STATUS_ERROR,
          generation_request:,
          task_description: nil,
          error_code: "E208"
        )
      )

      expect do
        result = service_call

        expect(result).to be_error
        expect(result.error_code).to eq("E208")
        expect(result.generation_request).to eq(generation_request)
        expect(result.task).to be_nil
      end.not_to change(Task, :count)
    end

    it "returns E301 when Task save fails and does not create Task (AC-03)" do
      generation_request = create(:generation_request, status: GenerationRequest::STATUS_SUCCESS)
      task_double = instance_double(Task, save: false)
      task_model_double = class_double(Task)

      allow(build_service).to receive(:call).with(params).and_return(
        build_result(
          state: GenerationRequest::STATUS_SUCCESS,
          generation_request:,
          task_description: "Warhammer 40K: выстрой строй. Реши через сортировка",
          error_code: nil
        )
      )
      allow(task_model_double).to receive(:new).with(description: "Warhammer 40K: выстрой строй. Реши через сортировка").and_return(task_double)

      result = nil

      expect do
        result = described_class.new(
          params,
          build_description_service: build_service,
          task_model: task_model_double
        ).call
      end.not_to change(Task, :count)

      expect(result).to be_error
      expect(result.error_code).to eq("E301")
      expect(result.generation_request).to eq(generation_request)
      expect(result.task).to be_nil
    end
  end
end
