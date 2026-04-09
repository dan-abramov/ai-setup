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
      # Временная заглушка: шаг валидации описания всегда успешен.
      success(normalize(task_description))
    end

    private

    attr_reader :task_description, :skill, :topic

    def normalize(value)
      strip_tags(value.to_s).strip
    end

    def success(task_description)
      Result.new(success: true, task_description:, error_code: nil)
    end
  end
end
