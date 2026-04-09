class GenerationFlowController < ApplicationController
  METRIC_WINDOW = 200

  def metrics
    requests = GenerationRequest
      .where(status: [ GenerationRequest::STATUS_SUCCESS, GenerationRequest::STATUS_ERROR ])
      .where.not(latency_ms: nil)
      .order(created_at: :desc)
      .limit(METRIC_WINDOW)

    total_count = requests.size
    success_count = requests.count { |request| request.status == GenerationRequest::STATUS_SUCCESS }
    p95_latency_ms = calculate_p95(requests.map(&:latency_ms))
    success_rate = total_count.zero? ? 0.0 : ((success_count.to_f / total_count) * 100).round(2)

    render json: {
      window_size: total_count,
      success_rate:,
      p95_latency_ms:,
      thresholds: {
        p95_max_ms: 1000,
        success_rate_min: 95.0
      },
      meets_slo: {
        p95: p95_latency_ms.present? && p95_latency_ms <= 1000,
        success_rate: success_rate >= 95.0
      }
    }
  end

  def show
    @generation_request = GenerationRequest.find_by(id: params[:id])

    return if flow_available?(@generation_request)

    redirect_to new_generation_request_path, alert: t("generation_flow.show.unavailable")
  end

  private

  def flow_available?(generation_request)
    return false unless generation_request

    generation_request.status == GenerationRequest::STATUS_SUCCESS && generation_request.task_description.present?
  end

  def calculate_p95(latencies)
    return nil if latencies.empty?

    sorted = latencies.sort
    index = ((sorted.length * 0.95).ceil - 1)
    sorted[index]
  end
end
