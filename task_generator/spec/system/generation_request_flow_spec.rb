require "rails_helper"

RSpec.describe "GenerationRequestFlow", type: :system do
  before do
    driven_by(:rack_test)
  end

  it "renders EMPTY state and hidden controls on first load" do
    visit new_generation_request_path

    expect(page).to have_content("Состояние: EMPTY")
    expect(page).to have_button("Сгенерировать")
    expect(page).to have_css("button.hidden", text: "Повторить")
    expect(page).to have_css("a.hidden", text: "Перейти к решению")
  end

  it "opens flow page for SUCCESS generation request" do
    request_record = create(
      :generation_request,
      status: GenerationRequest::STATUS_SUCCESS,
      task_description: "Warhammer 40K: выстрой строй. Реши через сортировка"
    )

    visit generation_flow_path(request_record.id)

    expect(page).to have_content("Переход к решению")
    expect(page).to have_content("Warhammer 40K: выстрой строй. Реши через сортировка")
  end

  it "redirects to form when flow guard is not satisfied" do
    request_record = create(:generation_request, :error, error_code: "E205")

    visit generation_flow_path(request_record.id)

    expect(page).to have_current_path(new_generation_request_path)
    expect(page).to have_content("Переход к решению доступен только после успешной генерации.")
  end
end
