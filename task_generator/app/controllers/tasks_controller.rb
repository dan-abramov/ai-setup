class TasksController < ApplicationController
  ERROR_NOT_FOUND = "E302"
  ERROR_UNAVAILABLE = "E303"

  def show
    @task = Task.find_by(id: params[:id])
    return render_error(ERROR_NOT_FOUND, :not_found) unless @task
    return render_error(ERROR_UNAVAILABLE, :unprocessable_content) if @task.description.blank?
  end

  private

  def render_error(error_code, status)
    @error_code = error_code
    render :show, status:
  end
end
