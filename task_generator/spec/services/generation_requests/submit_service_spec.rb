require "rails_helper"

RSpec.describe GenerationRequests::SubmitService, type: :service do
  describe ".call" do
    it "returns success and persists record for valid data" do
      result = described_class.call(skill: " Сортировка ", topic: " <b>Warhammer 40K</b> ")

      expect(result.status).to eq(:success)
      expect(result).to be_success
      expect(result.generation_request).to be_persisted
      expect(result.generation_request.skill).to eq("Сортировка")
      expect(result.generation_request.topic).to eq("Warhammer 40K")
      expect(result.error_code).to be_nil
    end

    it "returns validation_error for invalid data" do
      result = described_class.call(skill: "!!!", topic: "Ruby")

      expect(result.status).to eq(:validation_error)
      expect(result).to be_validation_error
      expect(result.generation_request).not_to be_persisted
      expect(result.generation_request.error_codes_for(:skill)).to eq(["E003"])
      expect(result.error_code).to be_nil
    end

    it "returns server_error with E007 when exception happens" do
      allow_any_instance_of(GenerationRequest).to receive(:save).and_raise(StandardError, "boom")

      result = described_class.call(skill: "Ruby", topic: "Warhammer")

      expect(result.status).to eq(:server_error)
      expect(result).to be_server_error
      expect(result.error_code).to eq("E007")
      expect(result.generation_request).not_to be_persisted
    end
  end
end
