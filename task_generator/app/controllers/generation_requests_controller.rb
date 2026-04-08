class GenerationRequestsController < ApplicationController
  def new
    @generation_request = GenerationRequest.new
  end

  def create
    result = GenerationRequests::SubmitService.call(generation_request_params)

    if result.success?
      render json: {
        state: GenerationRequest::STATUS_SUCCESS,
        generation_request_id: result.generation_request.id,
        task_description: result.task_description
      }
      return
    end

    payload = {
      state: GenerationRequest::STATUS_ERROR,
      error_code: result.error_code
    }

    if result.generation_request.present?
      payload[:generation_request_id] = result.generation_request.id
    end

    render json: payload, status: :unprocessable_content
  end

  private

  def generation_request_params
    params.fetch(:generation_request, {}).permit(:skill, :topic)
  end
end
