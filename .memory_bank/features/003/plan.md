Grounding (проверено в репозитории перед планированием):
- Уже существуют и будут изменяться: `task_generator/config/routes.rb`, `task_generator/app/controllers/generation_requests_controller.rb`, `task_generator/app/services/generation_requests/submit_service.rb`, `task_generator/app/services/generation/build_description_service.rb`, `task_generator/app/javascript/controllers/generation_request_form_controller.js`, `task_generator/app/views/generation_requests/new.html.erb`, `task_generator/spec/requests/generation_requests_spec.rb`, `task_generator/spec/services/generation_requests/submit_service_spec.rb`, `task_generator/spec/services/generation/build_description_service_spec.rb`, `task_generator/spec/system/generation_request_flow_spec.rb`, `task_generator/config/locales/ru.yml`, `task_generator/config/locales/en.yml`, `task_generator/README.md`.
- Сущность `Task` и связанные файлы в `task_generator/app/models`, `task_generator/app/controllers`, `task_generator/app/views`, `task_generator/spec` пока отсутствуют и должны быть созданы в рамках этой фичи.
- `generation_flow/:id` и `generation_flow/metrics` уже есть; в этой фиче не трогаем legacy-модуль `generation_flow`, чтобы не выходить за модульные границы из `spec.md`.

1. Добавить слой хранения `Task` (миграция + модель + базовые тесты).
Файлы:
- `task_generator/db/migrate/<timestamp>_create_tasks.rb` (new)
- `task_generator/app/models/task.rb` (new)
- `task_generator/spec/factories/tasks.rb` (new)
- `task_generator/spec/models/task_spec.rb` (new)
- `task_generator/db/schema.rb` (auto)
Что меняется:
- создаётся таблица `tasks` с полем `description`;
- `Task` валидирует `description` (presence, length <= 150);
- добавляются factory/spec для изолированной проверки модели.
Проверка шага: `cd task_generator && bin/rails db:migrate && bundle exec rspec spec/models/task_spec.rb`.

2. Вернуть контракт ошибок генерации `E206-E209` в pipeline генерации до создания `Task`.
Файлы:
- `task_generator/app/services/generation/build_description_service.rb`
- `task_generator/spec/services/generation/build_description_service_spec.rb`
Что меняется:
- после ответа AI вызывается `Generation::DescriptionValidator`;
- при провале валидатора сервис возвращает `ERROR` с кодом `E206-E209` и не завершает запрос как `SUCCESS`;
- при валидном описании сохраняется нормализованный `task_description`;
- поведение входных ошибок `E201-E203` остаётся без изменений.
Проверка шага: `cd task_generator && bundle exec rspec spec/services/generation/build_description_service_spec.rb`.

3. Реализовать endpoint повторного открытия `GET /task/:id` с предсказуемыми ошибками `E302/E303`.
Файлы:
- `task_generator/config/routes.rb`
- `task_generator/app/controllers/tasks_controller.rb` (new)
- `task_generator/app/views/tasks/show.html.erb` (new)
- `task_generator/config/locales/ru.yml`
- `task_generator/config/locales/en.yml`
- `task_generator/spec/requests/tasks_spec.rb` (new)
Что меняется:
- добавляется маршрут `GET /task/:id` (helper: `task_path`);
- `TasksController#show` открывает задачу без повторной генерации;
- при отсутствии записи отдаётся ошибка `E302` (предсказуемый ответ с кодом);
- при `description.blank?` отдаётся ошибка `E303` (предсказуемый ответ с кодом);
- тексты ошибок/заголовков выносятся в i18n.
Проверка шага: `cd task_generator && bundle exec rspec spec/requests/tasks_spec.rb`.

4. Расширить `GenerationRequests::SubmitService` до оркестрации создания `Task`.
Файлы:
- `task_generator/app/services/generation_requests/submit_service.rb`
- `task_generator/spec/services/generation_requests/submit_service_spec.rb`
Что меняется:
- сервис вызывает `BuildDescriptionService`;
- при `SUCCESS` пытается создать `Task` из `task_description`;
- при ошибке сохранения `Task` возвращает `ERROR/E301` и не создаёт запись `Task`;
- для `E201-E209` поведение остаётся passthrough без создания `Task`;
- контракт результата сервиса фиксируется полями для контроллера (`task`, `error_code`, `generation_request`).
Проверка шага: `cd task_generator && bundle exec rspec spec/services/generation_requests/submit_service_spec.rb`.

5. Зафиксировать однозначный HTTP-контракт `POST /generation_requests`.
Файлы:
- `task_generator/app/controllers/generation_requests_controller.rb`
- `task_generator/spec/requests/generation_requests_spec.rb`
Что меняется:
- успех возвращает строго:
  - `state: "SUCCESS"`
  - `task_id`
  - `task_path`
- ошибка возвращает строго:
  - `state: "ERROR"`
  - `error_code`
  - `generation_request_id` только когда есть persisted `GenerationRequest` (например, `E204-E209`, `E301`);
- в тестах фиксируется инвариант: `Task.count` не растёт на `E201-E209/E301`.
Проверка шага: `cd task_generator && bundle exec rspec spec/requests/generation_requests_spec.rb`.

6. Обновить клиентский flow формы: после `SUCCESS` делать немедленный переход на `GET /task/:id`.
Файлы:
- `task_generator/app/javascript/controllers/generation_request_form_controller.js`
- `task_generator/app/views/generation_requests/new.html.erb`
- `task_generator/config/locales/ru.yml`
- `task_generator/config/locales/en.yml`
Что меняется:
- Stimulus использует `payload.task_path` и делает redirect через `window.location.assign(...)`;
- legacy-ссылка на `generation_flow` убирается из UI;
- retry-логика расширяется на `E301`;
- добавляются i18n-сообщения `E301` в `generation_requests.errors.codes`.
Проверка шага: `cd task_generator && bundle exec rspec spec/requests/generation_requests_spec.rb`.

7. Довести покрытие acceptance-критериев в атомарных тестах.
Файлы:
- `task_generator/spec/services/generation_requests/submit_service_spec.rb` (`AC-01`, `AC-03`)
- `task_generator/spec/requests/generation_requests_spec.rb` (`AC-01`, `AC-02`, `AC-03`)
- `task_generator/spec/requests/tasks_spec.rb` (`AC-04`, `AC-05`, `AC-06`, `AC-07`, `AC-08`)
- `task_generator/spec/system/generation_request_flow_spec.rb` (`AC-07` smoke на уровне UI-навигации)
Что меняется:
- покрываются инварианты: одна `Task` на один успешный submit, отсутствие `Task` на ошибках, reopen без новой генерации;
- `AC-08` фиксируется отдельным сценарием на окне 200 reopen-запросов к `GET /task/:id`, где доля успешных открытий должна быть >= 95%.
Проверка шага: `cd task_generator && bundle exec rspec spec/services/generation_requests/submit_service_spec.rb spec/requests/generation_requests_spec.rb spec/requests/tasks_spec.rb spec/system/generation_request_flow_spec.rb`.

8. Обновить документацию по публичному контракту фичи.
Файлы:
- `task_generator/README.md`
Что меняется:
- описывается новый маршрут пользователя: `POST /generation_requests` -> `GET /task/:id`;
- фиксируются JSON-контракты ответа (`SUCCESS` с `task_id/task_path`, `ERROR` с `error_code`);
- описываются коды `E301-E303` и правило «не создавать `Task` на `E201-E209/E301`»;
- добавляется сценарий повторного открытия задачи по URL после закрытия вкладки.
Проверка шага: README позволяет воспроизвести `AC-01..AC-08` без чтения исходников.

9. Прогнать целостную регрессию фичи.
Файлы:
- без изменений кода (проверочный шаг)
Что меняется:
- выполняется полный прогон RSpec, проверяется совместимость миграций/контрактов/роутинга;
- отдельно подтверждается, что существующие тесты по `generation_flow/metrics` остаются зелёными.
Проверка шага: `cd task_generator && bundle exec rspec`.
