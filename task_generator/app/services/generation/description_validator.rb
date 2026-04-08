module Generation
  class DescriptionValidator
    include ActionView::Helpers::SanitizeHelper

    Result = Data.define(:success, :task_description, :error_code) do
      def success?
        success
      end
    end

    MAX_LENGTH = 150
    REQUIRED_PHRASE = "Реши через"

    ERROR_CODES = {
      blank: "E206",
      too_long: "E207",
      missing_topic: "E208",
      missing_skill_or_phrase: "E209"
    }.freeze

    def self.call(task_description:, skill:, topic:)
      new(task_description:, skill:, topic:).call
    end

    def initialize(task_description:, skill:, topic:)
      @task_description = task_description
      @skill = skill
      @topic = topic
    end

    def call
      normalized_description = normalize(task_description)
      normalized_skill = normalize(skill)
      normalized_topic = normalize(topic)

      return failure(ERROR_CODES[:blank]) if normalized_description.blank?
      return failure(ERROR_CODES[:too_long]) if normalized_description.length > MAX_LENGTH
      return failure(ERROR_CODES[:missing_topic]) unless includes_case_insensitive?(normalized_description, normalized_topic)

      unless includes_case_insensitive?(normalized_description, normalized_skill) && includes_case_insensitive?(normalized_description, REQUIRED_PHRASE)
        return failure(ERROR_CODES[:missing_skill_or_phrase])
      end

      success(normalized_description)
    end

    private

    attr_reader :task_description, :skill, :topic

    def normalize(value)
      strip_tags(value.to_s).strip
    end

    def includes_case_insensitive?(value, fragment)
      return false if value.blank? || fragment.blank?

      value.downcase.include?(fragment.downcase)
    end

    def success(task_description)
      Result.new(success: true, task_description:, error_code: nil)
    end

    def failure(error_code)
      Result.new(success: false, task_description: nil, error_code:)
    end
  end
end
