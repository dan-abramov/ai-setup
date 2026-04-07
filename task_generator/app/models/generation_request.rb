class GenerationRequest < ApplicationRecord
  include ActionView::Helpers::SanitizeHelper

  MAX_LENGTH = 100
  CONTENT_FORMAT = /\A(?![^\p{Word}]*\z).{1,100}\z/u
  ERROR_CODES = {
    skill: {
      blank: "E001",
      too_long: "E002",
      invalid: "E003"
    },
    topic: {
      blank: "E004",
      too_long: "E005",
      invalid: "E006"
    }
  }.freeze

  before_validation :normalize_fields

  validate :validate_skill
  validate :validate_topic

  def error_codes_for(attribute)
    errors.messages_for(attribute).uniq
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
    validate_attribute(:skill, ERROR_CODES[:skill])
  end

  def validate_topic
    validate_attribute(:topic, ERROR_CODES[:topic])
  end

  def validate_attribute(attribute, codes)
    value = public_send(attribute)

    if value.blank?
      errors.add(attribute, codes[:blank])
      return
    end

    if value.length > MAX_LENGTH
      errors.add(attribute, codes[:too_long])
      return
    end

    errors.add(attribute, codes[:invalid]) unless CONTENT_FORMAT.match?(value)
  end
end
