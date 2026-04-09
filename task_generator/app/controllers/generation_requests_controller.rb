class GenerationRequestsController < ApplicationController
  def new
    @generation_request = GenerationRequest.new
  end

  def create
    result = GenerationRequests::SubmitService.call(generation_request_params)

    if result.success?
      render json: {
        state: GenerationRequest::STATUS_SUCCESS,
        task_id: result.task.id,
        task_path: task_path(result.task)
      }
      return
    end

    payload = {
      state: GenerationRequest::STATUS_ERROR,
      error_code: result.error_code
    }

    if result.generation_request&.persisted?
      payload[:generation_request_id] = result.generation_request.id
    end

    render json: payload, status: :unprocessable_content
  end

  private

  def generation_request_params
    params.fetch(:generation_request, {}).permit(:skill, :topic)
  end
end
