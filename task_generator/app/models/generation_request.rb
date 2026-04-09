class GenerationRequest < ApplicationRecord
  include ActionView::Helpers::SanitizeHelper

  MAX_LENGTH = 100
  STATUS_EMPTY = "EMPTY"
  STATUS_LOADING = "LOADING"
  STATUS_SUCCESS = "SUCCESS"
  STATUS_ERROR = "ERROR"

  ERROR_CODES = {
    skill_blank: "E201",
    topic_blank: "E202",
    invalid_length: "E203"
  }.freeze

  before_validation :normalize_fields

  validate :validate_skill
  validate :validate_topic

  def error_codes_for(attribute)
    errors.messages_for(attribute).uniq
  end

  def input_error_codes
    [ :skill, :topic ].flat_map { |attribute| error_codes_for(attribute) }.uniq
  end

  def first_input_error_code
    input_error_codes.first
  end

  private

  def normalize_fields
    self.skill = sanitize_and_trim(skill)
    self.topic = sanitize_and_trim(topic)
  end

  def sanitize_and_trim(value)
    strip_tags(value.to_s).strip
  end

  def validate_skill
    validate_presence_and_length(:skill, blank_code: ERROR_CODES[:skill_blank])
  end

  def validate_topic
    validate_presence_and_length(:topic, blank_code: ERROR_CODES[:topic_blank])
  end

  def validate_presence_and_length(attribute, blank_code:)
    value = public_send(attribute)

    if value.blank?
      errors.add(attribute, blank_code)
      return
    end

    errors.add(attribute, ERROR_CODES[:invalid_length]) if value.length > MAX_LENGTH
  end
end
