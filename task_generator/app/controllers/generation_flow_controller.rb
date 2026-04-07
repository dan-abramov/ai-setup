class GenerationFlowController < ApplicationController
  def show
    @skill = params[:skill].to_s
    @topic = params[:topic].to_s
  end
end
