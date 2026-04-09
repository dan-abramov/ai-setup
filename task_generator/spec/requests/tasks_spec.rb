require "rails_helper"

RSpec.describe "Tasks", type: :request do
  describe "GET /task/:id" do
    it "returns 200 and renders description for existing task (AC-04)" do
      task = create(:task, description: "Warhammer 40K: выстрой строй. Реши через сортировка")

      get task_path(task)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Warhammer 40K: выстрой строй. Реши через сортировка")
    end

    it "returns E302 for missing task id (AC-05)" do
      get task_path(id: 999_999)

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("E302")
      expect(response.body).to include("Задача не найдена")
    end

    it "returns E303 for task with blank description (AC-06)" do
      task = Task.create!(description: "Временное описание")
      task.update_column(:description, " ")

      get task_path(task)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("E303")
      expect(response.body).to include("Задача недоступна для открытия")
    end

    it "reopens the same task URL multiple times without new generation (AC-07)" do
      task = create(:task, description: "Warhammer 40K: выстрой строй. Реши через сортировка")

      expect(Generation::AiClient).not_to receive(:call)

      expect do
        get task_path(task)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(task.description)

        get task_path(task)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(task.description)
      end.not_to change(GenerationRequest, :count)
    end

    it "keeps reopen success rate >= 95% for window of 200 requests (AC-08)" do
      tasks = create_list(:task, 200)
      success_count = 0

      tasks.each do |task|
        get task_path(task)
        success_count += 1 if response.status == 200 && response.body.include?(task.description)
      end

      success_rate = (success_count.to_f / tasks.size) * 100
      expect(success_rate).to be >= 95.0
    end
  end
end
