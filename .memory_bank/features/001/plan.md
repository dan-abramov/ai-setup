1. Подготовить серверную модель данных для skill/topic.
Файлы:
- task_generator/db/migrate/<timestamp>_create_generation_requests.rb (new)
- task_generator/app/models/generation_request.rb (new)
- task_generator/db/schema.rb (auto)
Что меняется: создаётся таблица generation_requests (skill, topic, timestamps); в модели реализуются strip_tags + trim и проверка `^(?!\W*$).{1,100}$`; валидации маппятся на E001-E006.
Проверка шага: `cd task_generator && bin/rails db:migrate` + точечная проверка в `bin/rails runner`.

2. Вынести оркестрацию перехода в service object.
Файлы:
- task_generator/app/services/generation_requests/submit_service.rb (new)
Что меняется: сервис принимает сырые параметры формы, нормализует их, сохраняет запись, возвращает результат (`success`, `validation_error`, `server_error` с кодом E007 при исключении/timeout).
Проверка шага: `cd task_generator && bin/rails runner` для успешного и ошибочного кейса сервиса.

3. Добавить HTTP-слой формы (роутинг + контроллер).
Файлы:
- task_generator/config/routes.rb
- task_generator/app/controllers/generation_requests_controller.rb (new)
Что меняется: добавляются GET/POST для шага ввода skill/topic; контроллер вызывает сервис, блокирует переход при невалидных данных и передаёт ошибки в view.
Проверка шага: `cd task_generator && bin/rails routes | rg generation_requests`.

4. Сделать форму и локализацию ошибок.
Файлы:
- task_generator/app/views/generation_requests/new.html.erb (new)
- task_generator/config/locales/ru.yml (new)
- task_generator/config/application.rb
Что меняется: форма с полями `Навык`/`Тема`, вывод E001-E006 под полями и E007 как общий alert; выставляется `config.i18n.default_locale = :ru`.
Проверка шага: ручной прогон сценариев E001-E007 через браузер/POST.

5. Реализовать следующий шаг-приёмник (без изменения логики генерации).
Файлы:
- task_generator/app/controllers/generation_flow_controller.rb (new)
- task_generator/app/views/generation_flow/show.html.erb (new)
- task_generator/config/routes.rb
Что меняется: после успешного submit выполняется редирект на следующий шаг, где доступны переданные `skill` и `topic`.
Проверка шага: валидный submit приводит на экран-приёмник с отображением обоих значений.

6. Добавить клиентскую валидацию и machine states (EMPTY/ERROR/READY/LOADING).
Файлы:
- task_generator/app/javascript/controllers/generation_request_form_controller.js (new)
- task_generator/app/views/generation_requests/new.html.erb
- task_generator/app/assets/stylesheets/application.css
Что меняется: валидация до submit, `disabled/enabled` кнопки, текст `Генерация...`, блок двойной отправки и реакции UI.
Проверка шага: независимый ручной UI-smoke (без автотестов этого шага).

7. Покрыть фичу автотестами на RSpec + FactoryBot.
Файлы:
- task_generator/spec/models/generation_request_spec.rb (new)
- task_generator/spec/services/generation_requests/submit_service_spec.rb (new)
- task_generator/spec/requests/generation_requests_spec.rb (new)
- task_generator/spec/system/generation_request_flow_spec.rb (new)
- task_generator/spec/factories/generation_requests.rb (new)
Что меняется: тесты на E001-E007, блокировку перехода, успешный переход и передачу `skill/topic`, сохранение значений при ошибках.
Проверка шага: `cd task_generator && bundle exec rspec`.

8. Обновить документацию фичи.
Файлы:
- task_generator/README.md
Что меняется: описывается новый пользовательский шаг, ограничения ввода, коды ошибок и запуск проверок/тестов (`bundle exec rspec`).
Проверка шага: README воспроизводит сценарий от формы до перехода.
