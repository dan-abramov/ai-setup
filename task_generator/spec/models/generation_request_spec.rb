require "rails_helper"

RSpec.describe GenerationRequest, type: :model do
  describe "normalization" do
    it "strips html tags and trims spaces" do
      request = described_class.new(
        skill: " <b>Сортировка</b> ",
        topic: " <i>Warhammer 40K</i> "
      )

      request.validate

      expect(request.skill).to eq("Сортировка")
      expect(request.topic).to eq("Warhammer 40K")
    end
  end

  describe "validations" do
    it "returns E201 for blank skill" do
      request = described_class.new(skill: " ", topic: "Ruby")

      request.validate

      expect(request.error_codes_for(:skill)).to eq(["E201"])
      expect(request.first_input_error_code).to eq("E201")
    end

    it "returns E202 for blank topic" do
      request = described_class.new(skill: "Ruby", topic: " ")

      request.validate

      expect(request.error_codes_for(:topic)).to eq(["E202"])
      expect(request.first_input_error_code).to eq("E202")
    end

    it "returns E203 for skill longer than 100 chars" do
      request = described_class.new(skill: "a" * 101, topic: "Ruby")

      request.validate

      expect(request.error_codes_for(:skill)).to eq(["E203"])
      expect(request.first_input_error_code).to eq("E203")
    end

    it "returns E203 for topic longer than 100 chars" do
      request = described_class.new(skill: "Ruby", topic: "a" * 101)

      request.validate

      expect(request.error_codes_for(:topic)).to eq(["E203"])
      expect(request.first_input_error_code).to eq("E203")
    end

    it "is valid for normalized input lengths 1..100" do
      request = described_class.new(skill: " <b>Ruby</b> ", topic: " Rails ")

      expect(request).to be_valid
      expect(request.input_error_codes).to eq([])
    end
  end
end
