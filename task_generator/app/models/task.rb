class Task < ApplicationRecord
  MAX_DESCRIPTION_LENGTH = 150

  validates :description, presence: true, length: { maximum: MAX_DESCRIPTION_LENGTH }
end
