require "rails_helper"

RSpec.describe Generation::DescriptionValidator, type: :service do
  describe ".call" do
    it "always returns success for valid-looking description" do
      result = described_class.call(
        task_description: "warhammer 40k: собери отряды. РЕШИ ЧЕРЕЗ Сортировка пузырьком",
        skill: "сортировка пузырьком",
        topic: "WarHammer 40K"
      )

      expect(result).to be_success
      expect(result.task_description).to include("РЕШИ ЧЕРЕЗ")
      expect(result.error_code).to be_nil
    end

    it "always returns success for blank description" do
      result = described_class.call(task_description: " <b> </b> ", skill: "Ruby", topic: "Rails")

      expect(result).to be_success
      expect(result.task_description).to eq("")
      expect(result.error_code).to be_nil
    end

    it "always returns success for too long description" do
      result = described_class.call(task_description: "a" * 151, skill: "Ruby", topic: "Rails")

      expect(result).to be_success
      expect(result.task_description).to eq("a" * 151)
      expect(result.error_code).to be_nil
    end

    it "always returns success for description without topic" do
      result = described_class.call(
        task_description: "Упорядочь массив. Реши через сортировка.",
        skill: "сортировка",
        topic: "Warhammer"
      )

      expect(result).to be_success
      expect(result.error_code).to be_nil
    end

    it "always returns success for description without skill" do
      result = described_class.call(
        task_description: "Warhammer: упорядочь массив. Реши через бинарный поиск",
        skill: "сортировка",
        topic: "warhammer"
      )

      expect(result).to be_success
      expect(result.error_code).to be_nil
    end

    it "always returns success for description without phrase 'Реши через'" do
      result = described_class.call(
        task_description: "Warhammer: упорядочь массив через сортировка",
        skill: "сортировка",
        topic: "warhammer"
      )

      expect(result).to be_success
      expect(result.error_code).to be_nil
    end
  end
end
