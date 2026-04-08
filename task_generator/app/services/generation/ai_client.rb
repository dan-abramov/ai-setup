require "json"
require "net/http"

module Generation
  class AiClient
    Result = Data.define(:success, :task_description, :error_code) do
      def success?
        success
      end
    end

    ERROR_TIMEOUT = "E204"
    ERROR_PROVIDER = "E205"

    SYSTEM_PROMPT = <<~PROMPT.freeze
      Ты генерируешь краткое описание задачи по Ruby.
      Верни только один короткий абзац plain text без HTML.
      В тексте обязательно должна быть фраза "Реши через".
    PROMPT

    def self.call(skill:, topic:)
      new(skill:, topic:).call
    end

    def initialize(skill:, topic:, config: Rails.application.config.x.generation)
      @skill = skill
      @topic = topic
      @config = config
    end

    def call
      return failure(ERROR_PROVIDER) if api_key.blank?

      models.each_with_index do |model, index|
        result = call_model(model)
        return result if result.success?
        return result if result.error_code == ERROR_TIMEOUT

        next if index.zero?

        return result
      end

      failure(ERROR_PROVIDER)
    end

    private

    attr_reader :skill, :topic, :config

    def call_model(model)
      response = perform_request(model)
      return failure(ERROR_PROVIDER) unless response.is_a?(Net::HTTPSuccess)

      description = extract_description(response.body)
      return failure(ERROR_PROVIDER) if description.blank?

      success(description)
    rescue Net::OpenTimeout, Net::ReadTimeout, Timeout::Error
      failure(ERROR_TIMEOUT)
    rescue SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ETIMEDOUT, JSON::ParserError, IOError
      failure(ERROR_PROVIDER)
    rescue StandardError
      failure(ERROR_PROVIDER)
    end

    def perform_request(model)
      uri = URI.parse(config.openrouter_api_url)
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{api_key}"
      request["Content-Type"] = "application/json"
      request.body = JSON.generate(request_payload(model))

      Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout: timeout_seconds,
        read_timeout: timeout_seconds
      ) { |http| http.request(request) }
    end

    def request_payload(model)
      {
        model: model,
        messages: [
          { role: "system", content: SYSTEM_PROMPT },
          { role: "user", content: user_prompt }
        ],
        temperature: 0.4
      }
    end

    def user_prompt
      <<~PROMPT
        Навык: #{skill}
        Тема: #{topic}

        Сформулируй описание учебной задачи до 150 символов.
        Упомяни тему и навык. Добавь фразу "Реши через".
      PROMPT
    end

    def extract_description(body)
      payload = JSON.parse(body)
      payload.dig("choices", 0, "message", "content").to_s.strip
    end

    def models
      [ config.openrouter_primary_model, config.openrouter_fallback_model ]
    end

    def api_key
      config.openrouter_api_key.to_s
    end

    def timeout_seconds
      config.openrouter_timeout_seconds.to_i
    end

    def success(task_description)
      Result.new(success: true, task_description:, error_code: nil)
    end

    def failure(error_code)
      Result.new(success: false, task_description: nil, error_code:)
    end
  end
end
