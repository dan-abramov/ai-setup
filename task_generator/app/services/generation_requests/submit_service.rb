module GenerationRequests
  class SubmitService
    def self.call(raw_params)
      Generation::BuildDescriptionService.call(raw_params)
    end
  end
end
