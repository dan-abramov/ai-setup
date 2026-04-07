require "rails_helper"

RSpec.describe GenerationRequest, type: :model do
  describe "normalization" do
    it "strips html tags and trims spaces" do
      request = described_class.create!(
        skill: " <b>Сортировка</b> ",
        topic: " <i>Warhammer 40K</i> "
      )

      expect(request.skill).to eq("Сортировка")
      expect(request.topic).to eq("Warhammer 40K")
    end
  end

  describe "error codes mapping" do
    it "returns E001 for blank skill" do
      request = build(:generation_request, skill: "   ")

      request.validate

      expect(request.error_codes_for(:skill)).to eq(["E001"])
    end

    it "returns E002 for skill longer than 100 chars" do
      request = build(:generation_request, skill: "a" * 101)

      request.validate

      expect(request.error_codes_for(:skill)).to eq(["E002"])
    end

    it "returns E003 for skill with only non-word symbols" do
      request = build(:generation_request, skill: "!!!")

      request.validate

      expect(request.error_codes_for(:skill)).to eq(["E003"])
    end

    it "returns E004 for blank topic" do
      request = build(:generation_request, topic: "   ")

      request.validate

      expect(request.error_codes_for(:topic)).to eq(["E004"])
    end

    it "returns E005 for topic longer than 100 chars" do
      request = build(:generation_request, topic: "a" * 101)

      request.validate

      expect(request.error_codes_for(:topic)).to eq(["E005"])
    end

    it "returns E006 for topic with only non-word symbols" do
      request = build(:generation_request, topic: "!!!")

      request.validate

      expect(request.error_codes_for(:topic)).to eq(["E006"])
    end
  end
end
