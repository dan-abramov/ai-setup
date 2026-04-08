require "rails_helper"

RSpec.describe Generation::DescriptionValidator, type: :service do
  describe ".call" do
    it "returns success for valid description (case-insensitive checks)" do
      result = described_class.call(
        task_description: "warhammer 40k: собери отряды. РЕШИ ЧЕРЕЗ Сортировка пузырьком",
        skill: "сортировка пузырьком",
        topic: "WarHammer 40K"
      )

      expect(result).to be_success
      expect(result.task_description).to include("РЕШИ ЧЕРЕЗ")
      expect(result.error_code).to be_nil
    end

    it "returns E206 when description is blank after normalization" do
      result = described_class.call(task_description: " <b> </b> ", skill: "Ruby", topic: "Rails")

      expect(result).not_to be_success
      expect(result.error_code).to eq("E206")
    end

    it "returns E207 when description is longer than 150 chars" do
      result = described_class.call(task_description: "a" * 151, skill: "Ruby", topic: "Rails")

      expect(result).not_to be_success
      expect(result.error_code).to eq("E207")
    end

    it "returns E208 when description does not include topic" do
      result = described_class.call(
        task_description: "Упорядочь массив. Реши через сортировка.",
        skill: "сортировка",
        topic: "Warhammer"
      )

      expect(result).not_to be_success
      expect(result.error_code).to eq("E208")
    end

    it "returns E209 when description does not include skill" do
      result = described_class.call(
        task_description: "Warhammer: упорядочь массив. Реши через бинарный поиск",
        skill: "сортировка",
        topic: "warhammer"
      )

      expect(result).not_to be_success
      expect(result.error_code).to eq("E209")
    end

    it "returns E209 when description does not include phrase 'Реши через'" do
      result = described_class.call(
        task_description: "Warhammer: упорядочь массив через сортировка",
        skill: "сортировка",
        topic: "warhammer"
      )

      expect(result).not_to be_success
      expect(result.error_code).to eq("E209")
    end
  end
end
