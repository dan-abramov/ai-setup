module Generation
  class BuildDescriptionService
    Result = Data.define(:state, :generation_request, :task_description, :error_code) do
      def success?
        state == GenerationRequest::STATUS_SUCCESS
      end

      def error?
        state == GenerationRequest::STATUS_ERROR
      end
    end

    DEFAULT_ERROR_CODE = Generation::AiClient::ERROR_PROVIDER

    def self.call(raw_params)
      new(raw_params).call
    end

    def initialize(raw_params, ai_client: Generation::AiClient)
      params_hash = raw_params.to_h.symbolize_keys.slice(:skill, :topic)
      @raw_params = params_hash
      @ai_client = ai_client
      @generation_request = nil
      @started_at = nil
    end

    def call
      input_request = GenerationRequest.new(raw_params)
      return input_error_result(input_request) unless input_request.valid?

      @generation_request = GenerationRequest.create!(
        skill: input_request.skill,
        topic: input_request.topic,
        status: GenerationRequest::STATUS_LOADING
      )

      @started_at = monotonic_time

      ai_result = ai_client.call(skill: generation_request.skill, topic: generation_request.topic)
      return fail_generation(ai_result.error_code) unless ai_result.success?

      generation_request.update!(
        status: GenerationRequest::STATUS_SUCCESS,
        error_code: nil,
        task_description: ai_result.task_description,
        latency_ms: elapsed_ms
      )

      Result.new(
        state: GenerationRequest::STATUS_SUCCESS,
        generation_request:,
        task_description: generation_request.task_description,
        error_code: nil
      )
    rescue StandardError => e
      Rails.logger.error("[Generation::BuildDescriptionService] #{e.class}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n")) if e.backtrace

      fail_generation(DEFAULT_ERROR_CODE)
    end

    private

    attr_reader :raw_params, :ai_client, :generation_request

    def input_error_result(input_request)
      Result.new(
        state: GenerationRequest::STATUS_ERROR,
        generation_request: nil,
        task_description: nil,
        error_code: input_request.first_input_error_code
      )
    end

    def fail_generation(error_code)
      if generation_request&.persisted?
        generation_request.update_columns(
          status: GenerationRequest::STATUS_ERROR,
          error_code: error_code,
          task_description: nil,
          latency_ms: elapsed_ms,
          updated_at: Time.current
        )
      end

      Result.new(
        state: GenerationRequest::STATUS_ERROR,
        generation_request:,
        task_description: nil,
        error_code:
      )
    end

    def monotonic_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def elapsed_ms
      return nil unless @started_at

      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - @started_at
      (elapsed * 1000.0).round
    end
  end
end
