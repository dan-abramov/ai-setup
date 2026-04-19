require "rails_helper"

RSpec.describe "Tasks", type: :request do
  describe "GET /task/:id" do
    it "returns 200 and renders description for existing task (AC-04)" do
      solution_code = "units = [2, 1, 4, 3]\nputs units.sort.join(\"<\")"
      task = create(
        :task,
        description: "Warhammer 40K: выстрой строй. Реши через сортировка",
        solution_code:
      )

      get task_path(task)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Warhammer 40K: выстрой строй. Реши через сортировка")
      expect(response.body).to include("Код решения")
      expect(response.body).to include("name=\"task[solution_code]\"")
      expect(response.body).to include(ERB::Util.html_escape(solution_code))
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

    it "renders solution code as escaped text (NEG-02)" do
      solution_code = "<script>alert('xss')</script>"
      task = create(:task, solution_code:)

      get task_path(task)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;")
    end
  end

  describe "PATCH /task/:id" do
    it "saves solution code and redirects back to task page (SC-01)" do
      task = create(:task, solution_code: "")
      solution_code = "units = [2, 1, 4, 3]\nputs units.sort.join(\"<\")"

      patch update_task_path(task), params: { task: { solution_code: solution_code } }

      expect(response).to redirect_to(task_path(task))
      expect(task.reload.solution_code).to eq(solution_code)
    end

    it "clears saved solution code when blank value is submitted (SC-03)" do
      task = create(:task, solution_code: "puts :old_solution")

      patch update_task_path(task), params: { task: { solution_code: "" } }

      expect(response).to redirect_to(task_path(task))
      expect(task.reload.solution_code).to eq("")
    end

    it "returns E302 for missing task id on save (NEG-01)" do
      patch update_task_path(id: 999_999), params: { task: { solution_code: "puts :ok" } }

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("E302")
      expect(response.body).to include("Задача не найдена")
    end

    it "returns E303 for task with blank description on save" do
      task = Task.create!(description: "Временное описание")
      task.update_column(:description, " ")

      patch update_task_path(task), params: { task: { solution_code: "puts :ok" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("E303")
      expect(response.body).to include("Задача недоступна для открытия")
    end
  end
end
