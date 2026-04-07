class GenerationRequestsController < ApplicationController
  def new
    @generation_request = GenerationRequest.new
  end

  def create
    result = GenerationRequests::SubmitService.call(generation_request_params)

    if result.success?
      redirect_to generation_flow_path(
        skill: result.generation_request.skill,
        topic: result.generation_request.topic
      )
      return
    end

    @generation_request = result.generation_request

    if result.validation_error?
      render :new, status: :unprocessable_content
    else
      @server_error_code = result.error_code
      render :new, status: :internal_server_error
    end
  end

  private

  def generation_request_params
    params.require(:generation_request).permit(:skill, :topic)
  end
end
