require "rails_helper"

RSpec.describe "GenerationRequestFlow", type: :system do
  before do
    driven_by(:rack_test)
  end

  it "allows successful transition to the next step" do
    visit new_generation_request_path

    fill_in "Навык", with: "Сортировка"
    fill_in "Тема", with: "Warhammer 40K"
    click_button "Сгенерировать задачу"

    expect(page).to have_content("Следующий шаг")
    expect(page).to have_content("Навык: Сортировка")
    expect(page).to have_content("Тема: Warhammer 40K")
  end

  it "keeps entered values when validation fails" do
    visit new_generation_request_path

    fill_in "Навык", with: "!!!"
    fill_in "Тема", with: "Warhammer 40K"
    click_button "Сгенерировать задачу"

    expect(page).to have_content("E003")
    expect(page).to have_field("Навык", with: "!!!")
    expect(page).to have_field("Тема", with: "Warhammer 40K")
  end
end
