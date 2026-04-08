1. Расширить модель данных под полный цикл генерации.
Файлы:
- task_generator/db/migrate/20260408090000_add_generation_result_fields_to_generation_requests.rb (new)
- task_generator/db/schema.rb (auto)
Что меняется: в `generation_requests` добавляются поля `task_description:text`, `status:string`, `error_code:string`, `latency_ms:integer`; это нужно для состояний `EMPTY/LOADING/SUCCESS/ERROR`, передачи результата на следующий шаг и расчёта NFR.
Проверка шага: `cd task_generator && bin/rails db:migrate && bin/rails db:schema:dump`.

2. Привести модель `GenerationRequest` к контракту `valid request`.
Файлы:
- task_generator/app/models/generation_request.rb
Что меняется: нормализация `strip_tags + trim`; валидации только входа (`skill/topic` длина `1..100`) с кодами `E201`, `E202`, `E203`; helper-методы для чтения кодов ошибок.
Проверка шага: `cd task_generator && bin/rails runner 'r=GenerationRequest.new(skill:\" \",topic:\"Ruby\"); r.valid?; puts r.error_codes_for(:skill)'`.

3. Добавить конфигурацию OpenRouter и правила ошибок конфигурации.
Файлы:
- task_generator/config/initializers/generation.rb (new)
- task_generator/README.md
Что меняется: вводятся обязательные env-параметры (`OPENROUTER_API_KEY`, `OPENROUTER_TIMEOUT_SECONDS`), значения по умолчанию для timeout и единый маппинг ошибок конфигурации/отсутствующего ключа в `E205`.
Проверка шага: `cd task_generator && bin/rails runner 'puts Rails.application.config.x.generation.openrouter_timeout_seconds'` + ручная проверка, что README описывает поведение при пустом `OPENROUTER_API_KEY` (ошибка `E205`).

4. Добавить клиент генерации с primary/fallback и timeout.
Файлы:
- task_generator/app/services/generation/ai_client.rb (new)
Что меняется: `Generation::AiClient` на `Net::HTTP`, вызов OpenRouter с primary `qwen/qwen2.5-7b-instruct:free` и fallback `meta-llama/llama-3.1-8b-instruct:free`; timeout маппится в `E204`, сбой провайдера/оба недоступны/ошибка конфигурации — `E205`.
Проверка шага: `bin/rails runner` со stub/mock ответа HTTP для primary, fallback, timeout и ошибки.

5. Добавить валидатор результата генерации.
Файлы:
- task_generator/app/services/generation/description_validator.rb (new)
Что меняется: `Generation::DescriptionValidator` проверяет `task_description` после `strip_tags + trim`: не пусто (`E206`), длина `<=150` (`E207`), содержит `topic` без учёта регистра (`E208`), содержит `skill` без учёта регистра и фразу `Реши через` (`E209`).
Проверка шага: `bin/rails runner` с примерами валидного/невалидного текста, включая кейсы с разным регистром `skill/topic`.

6. Реализовать оркестрацию submit -> generation -> validate -> persist.
Файлы:
- task_generator/app/services/generation/build_description_service.rb (new)
- task_generator/app/services/generation_requests/submit_service.rb
Что меняется: `Generation::BuildDescriptionService` сначала валидирует вход; при `E201-E203` возвращает ошибку без создания записи в `generation_requests`; только для валидного входа создаёт `GenerationRequest`, выполняет генерацию/валидацию результата и обновляет `status`, `error_code`, `task_description`, `latency_ms`; `GenerationRequests::SubmitService` остаётся thin-wrapper и делегирует в `BuildDescriptionService`.
Проверка шага: `bin/rails runner` для success, `E201-E203`, `E204-E205`, `E206-E209`.

7. Реализовать HTTP-контракт submit (независимо от UI).
Файлы:
- task_generator/app/controllers/generation_requests_controller.rb
- task_generator/config/routes.rb
Что меняется: `POST /generation_requests` возвращает JSON-контракт:
- `200` + `{ state: "SUCCESS", generation_request_id, task_description }` для валидной генерации;
- `422` + `{ state: "ERROR", error_code }` для `E201-E209` (для `E201-E203` без `generation_request_id` и без сохранения записи в БД).
Проверка шага: `cd task_generator && bin/rails routes | rg generation_requests` + `curl`/request-smoke на `200` и `422`.

8. Реализовать шаг `GenerationFlow` c guard-условием.
Файлы:
- task_generator/app/controllers/generation_flow_controller.rb
- task_generator/app/views/generation_flow/show.html.erb
- task_generator/config/routes.rb
Что меняется: добавляется `GET /generation_flow/:id` (с `constraints: { id: /\\d+/ }`); endpoint принимает `generation_request.id`; переход разрешён только для `status=SUCCESS` и непустого `task_description`, иначе редирект на форму с ошибкой.
Проверка шага: ручной сценарий: success-запрос открывает flow; error-запрос не пускает в flow.

9. Обновить UI формы и state machine `EMPTY/LOADING/SUCCESS/ERROR`.
Файлы:
- task_generator/app/views/generation_requests/new.html.erb
- task_generator/app/javascript/controllers/generation_request_form_controller.js
- task_generator/app/assets/stylesheets/application.css
Что меняется: форма отправляет `POST /generation_requests` через JS, обрабатывает JSON-контракт шага 7, показывает `task_description` в `SUCCESS`, кнопку `Перейти к решению` (по `generation_request_id`) только в `SUCCESS`, кнопку `Повторить` только для `E204-E209`; двойная отправка блокируется в `LOADING`.
Проверка шага: ручной UI-smoke сценариев `EMPTY -> LOADING -> SUCCESS` и `EMPTY -> LOADING -> ERROR`.

10. Добавить локализацию сообщений и кодов ошибок.
Файлы:
- task_generator/config/locales/ru.yml
- task_generator/config/locales/en.yml
Что меняется: тексты для `E201-E209`, подписей состояний, кнопок `Сгенерировать`, `Повторить`, `Перейти к решению`, сообщений для server-side и client-side.
Проверка шага: переключение locale и проверка отображаемых сообщений.

11. Добавить endpoint метрик `AC-08` без нового доменного модуля.
Файлы:
- task_generator/app/controllers/generation_flow_controller.rb
- task_generator/config/routes.rb
Что меняется: добавляется `GET /generation_flow/metrics`, который считает `p95 latency` и `success_rate` на окне последних 200 валидных запросов напрямую по `GenerationRequest` и возвращает JSON для проверки `AC-08`; статический роут `generation_flow/metrics` объявляется выше `generation_flow/:id`, чтобы исключить конфликт маршрутов.
Проверка шага: `bin/rails runner`/request-smoke на тестовом наборе данных (>=200 валидных запросов).

12. Обновить unit/service-тесты под новый контракт.
Файлы:
- task_generator/spec/models/generation_request_spec.rb
- task_generator/spec/services/generation_requests/submit_service_spec.rb
- task_generator/spec/services/generation/ai_client_spec.rb (new)
- task_generator/spec/services/generation/description_validator_spec.rb (new)
- task_generator/spec/services/generation/build_description_service_spec.rb (new)
- task_generator/spec/factories/generation_requests.rb
Что меняется: покрытие `E201-E209`, primary/fallback/timeout, thin-wrapper `SubmitService`, проверка `case-insensitive` для `skill/topic`, корректное заполнение `status/error_code/task_description/latency_ms`.
Отдельно проверяется, что при `E201-E203` запись `generation_requests` не создаётся.
Проверка шага: `cd task_generator && bundle exec rspec spec/models spec/services`.

13. Обновить request/system-тесты под новый HTTP/UI-контракт.
Файлы:
- task_generator/spec/requests/generation_requests_spec.rb
- task_generator/spec/requests/generation_flow_spec.rb (new)
- task_generator/spec/system/generation_request_flow_spec.rb
Что меняется: покрытие ответов `200/422` и JSON-контракта submit, guard перехода в flow по `:id`, endpoint метрик `GET /generation_flow/metrics`, состояния UI и retry-правила.
Отдельно проверяется, что `422` для `E201-E203` не создаёт запись в БД и не возвращает `generation_request_id`.
Проверка шага: `cd task_generator && bundle exec rspec spec/requests spec/system`.

14. Обновить документацию фичи.
Файлы:
- task_generator/README.md
Что меняется: пользовательский сценарий (`submit -> generation -> SUCCESS/ERROR -> переход`), JSON-контракт submit, контракт ошибок `E201-E209`, требования к `task_description`, настройка OpenRouter (env), endpoint метрик и запуск тестов.
Проверка шага: README позволяет воспроизвести AC-01..AC-08 без чтения кода.
