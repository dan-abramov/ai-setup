module GenerationRequests
  class SubmitService
    Result = Data.define(:state, :task, :error_code, :generation_request) do
      def success?
        state == GenerationRequest::STATUS_SUCCESS
      end

      def error?
        state == GenerationRequest::STATUS_ERROR
      end
    end

    ERROR_TASK_SAVE = "E301"

    def self.call(raw_params)
      new(raw_params).call
    end

    def initialize(raw_params, build_description_service: Generation::BuildDescriptionService, task_model: Task)
      @raw_params = raw_params
      @build_description_service = build_description_service
      @task_model = task_model
    end

    def call
      generation_result = build_description_service.call(raw_params)
      return passthrough_error(generation_result) unless generation_result.success?

      task = task_model.new(description: generation_result.task_description)
      return success(task, generation_result.generation_request) if task.save

      Result.new(
        state: GenerationRequest::STATUS_ERROR,
        task: nil,
        error_code: ERROR_TASK_SAVE,
        generation_request: generation_result.generation_request
      )
    end

    private

    attr_reader :raw_params, :build_description_service, :task_model

    def success(task, generation_request)
      Result.new(
        state: GenerationRequest::STATUS_SUCCESS,
        task:,
        error_code: nil,
        generation_request:
      )
    end

    def passthrough_error(generation_result)
      Result.new(
        state: GenerationRequest::STATUS_ERROR,
        task: nil,
        error_code: generation_result.error_code,
        generation_request: generation_result.generation_request
      )
    end
  end
end
