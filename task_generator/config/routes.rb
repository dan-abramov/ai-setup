Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "generation_requests#new"

  resources :generation_requests, only: %i[new create]
  get "task/:id", to: "tasks#show", as: :task, constraints: { id: /\d+/ }

  get "generation_flow/metrics", to: "generation_flow#metrics"
  get "generation_flow/:id", to: "generation_flow#show", as: :generation_flow, constraints: { id: /\d+/ }
end
