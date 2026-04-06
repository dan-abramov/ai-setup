module GenerationRequests
  class SubmitService
    Result = Data.define(:status, :generation_request, :error_code) do
      def success?
        status == :success
      end

      def validation_error?
        status == :validation_error
      end

      def server_error?
        status == :server_error
      end
    end

    SERVER_ERROR_CODE = "E007"

    def self.call(raw_params)
      new(raw_params).call
    end

    def initialize(raw_params)
      params_hash = raw_params.to_h.symbolize_keys.slice(:skill, :topic)
      @raw_params = normalize_params(params_hash)
    end

    def call
      generation_request = GenerationRequest.new(@raw_params)

      if generation_request.save
        Result.new(status: :success, generation_request: generation_request, error_code: nil)
      else
        Result.new(status: :validation_error, generation_request: generation_request, error_code: nil)
      end
    rescue StandardError => e
      Rails.logger.error("[GenerationRequests::SubmitService] #{e.class}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n")) if e.backtrace

      Result.new(
        status: :server_error,
        generation_request: GenerationRequest.new(@raw_params),
        error_code: SERVER_ERROR_CODE
      )
    end

    private

    def normalize_params(params_hash)
      {
        skill: sanitize_and_trim(params_hash[:skill]),
        topic: sanitize_and_trim(params_hash[:topic])
      }
    end

    def sanitize_and_trim(value)
      ActionController::Base.helpers.strip_tags(value.to_s).strip
    end
  end
end
