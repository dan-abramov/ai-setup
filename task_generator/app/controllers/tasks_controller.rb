class TasksController < ApplicationController
  ERROR_NOT_FOUND = "E302"
  ERROR_UNAVAILABLE = "E303"

  def show
    @task = find_task
    return unless @task
    return render_error(ERROR_UNAVAILABLE, :unprocessable_content) if @task.description.blank?
  end

  def update
    @task = find_task
    return unless @task
    return render_error(ERROR_UNAVAILABLE, :unprocessable_content) if @task.description.blank?

    if @task.update(solution_code: solution_code_param)
      redirect_to task_path(@task), notice: t("tasks.show.solution_code_saved")
    else
      flash.now[:alert] = t("tasks.show.solution_code_save_failed")
      render :show, status: :unprocessable_content
    end
  end

  private

  def find_task
    task = Task.find_by(id: params[:id])
    return task if task

    render_error(ERROR_NOT_FOUND, :not_found)
    nil
  end

  def solution_code_param
    params.fetch(:task, {}).permit(:solution_code)[:solution_code].to_s
  end

  def render_error(error_code, status)
    @error_code = error_code
    render :show, status:
  end
end
