require "rails_helper"

RSpec.describe GenerationRequests::SubmitService, type: :service do
  describe ".call" do
    it "delegates to Generation::BuildDescriptionService" do
      params = { skill: "Ruby", topic: "Warhammer 40K" }
      result = instance_double(Generation::BuildDescriptionService::Result)

      expect(Generation::BuildDescriptionService).to receive(:call).with(params).and_return(result)

      expect(described_class.call(params)).to eq(result)
    end
  end
end
