require "rails_helper"

RSpec.describe "GenerationRequestFlow", type: :system do
  before do
    driven_by(:rack_test)
  end

  it "renders EMPTY state and hidden retry control on first load" do
    visit new_generation_request_path

    expect(page).to have_content("Состояние: EMPTY")
    expect(page).to have_button("Сгенерировать")
    expect(page).to have_css("button.hidden", text: "Повторить")
  end

  it "reopens task page by URL without regeneration (AC-07 smoke)" do
    task = create(:task, description: "Warhammer 40K: выстрой строй. Реши через сортировка")

    visit task_path(task)

    expect(page).to have_content("Сгенерированная задача")
    expect(page).to have_content("Warhammer 40K: выстрой строй. Реши через сортировка")

    visit task_path(task)
    expect(page).to have_current_path(task_path(task))
    expect(page).to have_content("Warhammer 40K: выстрой строй. Реши через сортировка")
  end
end
