require "rails_helper"

RSpec.describe Task, type: :model do
  describe "validations" do
    it "is valid with description up to 150 chars" do
      task = build(:task, description: "a" * 150)

      expect(task).to be_valid
    end

    it "is invalid when description is blank" do
      task = build(:task, description: " ")

      expect(task).not_to be_valid
      expect(task.errors.of_kind?(:description, :blank)).to eq(true)
    end

    it "is invalid when description is longer than 150 chars" do
      task = build(:task, description: "a" * 151)

      expect(task).not_to be_valid
      expect(task.errors.of_kind?(:description, :too_long)).to eq(true)
    end
  end
end
