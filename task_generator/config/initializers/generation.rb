Rails.application.configure do
  env_files = [
    Rails.root.join("..", ".env"),
    Rails.root.join("..", ".env.local"),
    Rails.root.join(".env"),
    Rails.root.join(".env.local")
  ]

  env_files.each do |file_path|
    next unless File.file?(file_path)

    File.foreach(file_path) do |line|
      sanitized = line.strip
      next if sanitized.empty? || sanitized.start_with?("#")

      key, value = sanitized.split("=", 2)
      next if key.blank? || value.nil?

      key = key.strip
      next unless key.start_with?("OPENROUTER_")
      next if ENV[key].to_s.strip.present?

      parsed_value = value.strip
      parsed_value = parsed_value[1..-2] if parsed_value.start_with?("\"") && parsed_value.end_with?("\"")
      parsed_value = parsed_value[1..-2] if parsed_value.start_with?("'") && parsed_value.end_with?("'")

      ENV[key] = parsed_value
    end
  end

  generation_config = ActiveSupport::OrderedOptions.new

  generation_config.openrouter_api_url = ENV.fetch(
    "OPENROUTER_API_URL",
    "https://openrouter.ai/api/v1/chat/completions"
  )
  generation_config.openrouter_api_key = ENV.fetch("OPENROUTER_API_KEY", "").to_s

  timeout_value = Integer(ENV.fetch("OPENROUTER_TIMEOUT_SECONDS", "1"), exception: false)
  generation_config.openrouter_timeout_seconds = timeout_value&.positive? ? timeout_value : 1

  generation_config.openrouter_primary_model = "arcee-ai/trinity-mini:free"
  generation_config.openrouter_fallback_model = "nvidia/nemotron-nano-9b-v2:free"
  generation_config.configuration_error_code = "E205"

  config.x.generation = generation_config
end
