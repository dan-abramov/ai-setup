require "rails_helper"

RSpec.describe "GenerationRequestFlow", type: :system do
  before do
    driven_by(:rack_test)
  end

  it "renders form without visible generation state and with hidden retry control on first load" do
    visit new_generation_request_path

    expect(page).not_to have_css(".state-badge")
    expect(page).not_to have_content("Состояние:")
    expect(page).to have_button("Сгенерировать")
    expect(page).to have_css("button.hidden", text: "Повторить")
  end

  it "reopens task page by URL without regeneration (AC-07 smoke)" do
    task = create(:task, description: "Warhammer 40K: выстрой строй. Реши через сортировка")

    visit task_path(task)

    expect(page).to have_content("Сгенерированная задача")
    expect(page).to have_content("Warhammer 40K: выстрой строй. Реши через сортировка")
    expect(page).to have_field("Код решения", type: "textarea")

    solution_code = "units = [2, 1, 4, 3]\nputs units.sort.join(\"<\")\nputs 'ready > done'"
    fill_in "Код решения", with: solution_code
    click_button "Сохранить код"
    expect(page).to have_content("Код решения сохранён.")
    expect(find_field("Код решения").value.gsub("\r\n", "\n")).to eq(solution_code)

    visit task_path(task)
    expect(page).to have_current_path(task_path(task))
    expect(page).to have_content("Warhammer 40K: выстрой строй. Реши через сортировка")
    expect(page).to have_field("Код решения", type: "textarea")
    expect(find_field("Код решения").value.gsub("\r\n", "\n")).to eq(solution_code)

    fill_in "Код решения", with: ""
    click_button "Сохранить код"
    expect(page).to have_content("Код решения сохранён.")
    expect(find_field("Код решения").value).to eq("")
  end
end
