class AddGenerationResultFieldsToGenerationRequests < ActiveRecord::Migration[7.1]
  def change
    add_column :generation_requests, :task_description, :text
    add_column :generation_requests, :status, :string, null: false, default: "EMPTY"
    add_column :generation_requests, :error_code, :string
    add_column :generation_requests, :latency_ms, :integer
  end
end
