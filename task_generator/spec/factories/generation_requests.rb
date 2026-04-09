FactoryBot.define do
  factory :generation_request do
    skill { "Сортировка пузырьком" }
    topic { "Warhammer 40K" }
    status { GenerationRequest::STATUS_SUCCESS }
    task_description { "Warhammer 40K: разложи строй. Реши через сортировка пузырьком." }
    error_code { nil }
    latency_ms { 450 }

    trait :loading do
      status { GenerationRequest::STATUS_LOADING }
      task_description { nil }
      error_code { nil }
      latency_ms { nil }
    end

    trait :error do
      status { GenerationRequest::STATUS_ERROR }
      task_description { nil }
      error_code { "E205" }
      latency_ms { 900 }
    end
  end
end
