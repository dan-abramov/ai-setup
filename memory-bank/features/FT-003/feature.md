---
title: "FT-003: Повторное открытие последней сгенерированной задачи после закрытия вкладки"
doc_kind: feature
doc_function: canonical
purpose: "Canonical-документ фичи сохранения и повторного открытия сгенерированной задачи по URL `GET /task/:id`."
derived_from:
  - ../../domain/problem.md
  - ../../prd/PRD-001-task-generator-mvp.md
status: done
delivery_status: archived
audience: humans_and_agents
must_not_define:
  - implementation_sequence
---

# FT-003: Повторное открытие последней сгенерированной задачи после закрытия вкладки

## What

### Problem

После закрытия вкладки пользователь теряет доступ к уже сгенерированному описанию задачи. Это снижает completion rate первого задания и угрожает KPI MVP.

Источник постановки:
- Brief: исходная документация в `.memory_bank/features/003/brief.md`.
- Tracker: [Issue #7](https://github.com/dan-abramov/ai-setup/issues/7).

### Outcome

| Metric ID | Metric | Baseline | Target | Measurement method |
| --- | --- | --- | --- | --- |
| `MET-01` | Доля сессий с успешным повторным открытием по URL `GET /task/:id` | `0%` | `>=95%` к 1 мая 2026 | Request/system тесты + reopen метрики |
| `MET-02` | Latency `submit -> redirect /task/:id` (p95) | не зафиксирован | `<=1s` на окне 200 валидных submit | Метрика из request слоя |

### Scope

- `REQ-01` На успешной генерации создавать отдельную сущность `Task` и сохранять `task_description` в `tasks.description`.
- `REQ-02` После создания `Task` переводить пользователя на `GET /task/:id`, чтобы страница открывалась повторно без новой генерации.
- `REQ-03` Для `POST /generation_requests` зафиксировать контракт успеха/ошибки с кодами `E301-E303` и правилом отсутствия `Task` на ошибках.
- `REQ-04` `GET /task/:id` должен возвращать сохранённое описание, а для невалидных состояний отдавать предсказуемые ошибки `E302/E303`.

### Non-Scope

- `NS-01` Не менять бизнес-логику и контракты ошибок генерации `E201-E209`.
- `NS-02` Не менять проверку пользовательского решения и генерацию автотестов решения.
- `NS-03` Не вводить историю из нескольких задач, списки, поиск и фильтры.

### Constraints / Assumptions

- `ASM-01` Существующий submit pipeline уже возвращает `SUCCESS/ERROR` и может быть расширен созданием `Task`.
- `CON-01` Не добавлять новые gem-зависимости без согласования.
- `CON-02` Придерживаться MVC + service objects.
- `CON-03` Не выходить за границы модулей: `GenerationRequests`, `Task`, `routes.rb`.
- `CON-04` Не изменять файлы вне проекта `ai-setup`.

## How

### Solution

Расширить submit-оркестрацию до создания `Task` при `SUCCESS`, отдать клиенту `task_path` и сделать `GET /task/:id` единственной страницей повторного открытия; ошибки сохранения и открытия задачи оформить как отдельные коды `E301-E303`.

### Change Surface

| Surface | Type | Why it changes |
| --- | --- | --- |
| `task_generator/db/migrate/*_create_tasks.rb` | data | Таблица для хранения reopenable задачи |
| `task_generator/app/models/task.rb` | code | Контракт валидности `description` |
| `task_generator/app/services/generation_requests/submit_service.rb` | code | Оркестрация создания `Task` после `BuildDescriptionService` |
| `task_generator/app/controllers/generation_requests_controller.rb` | code | JSON-контракт `SUCCESS/ERROR` с `task_id/task_path` |
| `task_generator/app/controllers/tasks_controller.rb` | code | Endpoint повторного открытия и ошибки `E302/E303` |
| `task_generator/app/views/tasks/show.html.erb` | code | Отображение сохранённого описания |
| `task_generator/config/routes.rb` | config | Маршруты `POST /generation_requests` и `GET /task/:id` |
| `task_generator/app/javascript/controllers/generation_request_form_controller.js` | code | Redirect на `task_path` и retry для `E301` |
| `task_generator/spec/**` | code | Покрытие AC-01..AC-08 |
| `task_generator/README.md` | doc | Публичный контракт reopen-потока |

### Flow

1. Пользователь отправляет `skill/topic` через `POST /generation_requests`.
2. Submit service вызывает генерацию описания; при `SUCCESS` пытается создать `Task`.
3. При успешном создании `Task` API возвращает `task_id` и `task_path`, фронтенд делает redirect.
4. При повторном открытии `GET /task/:id` контроллер читает `Task` и показывает `description` без новой генерации.

### Contracts

| Contract ID | Input / Output | Producer / Consumer | Notes |
| --- | --- | --- | --- |
| `CTR-01` | `POST /generation_requests` -> `SUCCESS { state, task_id, task_path }` | `GenerationRequestsController` -> frontend | Возвращается только после успешного создания `Task` |
| `CTR-02` | `POST /generation_requests` -> `ERROR { state, error_code, generation_request_id? }` | `GenerationRequestsController` -> frontend | `generation_request_id` включается только если есть persisted `GenerationRequest` |
| `CTR-03` | `GET /task/:id` -> `200` с описанием или `E302/E303` | `TasksController` -> browser/API client | Повторное открытие не инициирует новую генерацию |

### Failure Modes

- `FM-01` `Task` не сохранился после успешной генерации -> `E301`, переход на `/task/:id` не выполняется.
- `FM-02` Повторное открытие по отсутствующему id -> `E302`.
- `FM-03` `Task` найден, но `description.blank?` -> `E303`.

## Verify

### Exit Criteria

- `EC-01` Для успешного submit создаётся ровно один `Task`, и пользователь редиректится на `GET /task/:id`.
- `EC-02` При `E201-E209` и `E301` `Task.count` не увеличивается.
- `EC-03` `GET /task/:id` повторно открывает сохранённое описание без повторной генерации и корректно обрабатывает `E302/E303`.

### Traceability matrix

| Requirement ID | Design refs | Acceptance refs | Checks | Evidence IDs |
| --- | --- | --- | --- | --- |
| `REQ-01` | `CTR-01`, `FM-01` | `EC-01`, `SC-01` | `CHK-01`, `CHK-02` | `EVID-01`, `EVID-02` |
| `REQ-02` | `CTR-01`, `CTR-03` | `EC-01`, `EC-03`, `SC-01`, `SC-03` | `CHK-02`, `CHK-03` | `EVID-02`, `EVID-03` |
| `REQ-03` | `CTR-02`, `FM-01` | `EC-02`, `SC-02`, `NEG-01` | `CHK-01`, `CHK-02` | `EVID-01`, `EVID-02` |
| `REQ-04` | `CTR-03`, `FM-02`, `FM-03` | `EC-03`, `SC-03`, `SC-04`, `NEG-02` | `CHK-03` | `EVID-03` |

### Acceptance Scenarios

- `SC-01` Валидный submit создаёт одну запись `Task` и возвращает redirect-контракт на `GET /task/:id`.
- `SC-02` При `E201-E209` или `E301` API возвращает `ERROR`, а `Task.count` остаётся неизменным.
- `SC-03` Повторный `GET /task/:id` существующей задачи возвращает `200` и тот же `description` без новой генерации.
- `SC-04` `GET /task/:id` для несуществующей/невалидной задачи возвращает `E302` или `E303`.

### Negative / Edge Scenarios

- `NEG-01` Ошибка сохранения `Task` после успешного `BuildDescriptionService` возвращает `E301` и запрещает redirect.
- `NEG-02` Запрос на `GET /task/:id` с отсутствующим id или пустым `description` не приводит к генерации и возвращает предсказуемую ошибку.

### Checks

| Check ID | Covers | How to check | Expected result | Evidence path |
| --- | --- | --- | --- | --- |
| `CHK-01` | `EC-01`, `EC-02`, `SC-01`, `SC-02`, `NEG-01` | `cd task_generator && bundle exec rspec spec/services/generation_requests/submit_service_spec.rb spec/services/generation/build_description_service_spec.rb` | Контракт `Task` creation/no-creation выполняется | `artifacts/ft-003/verify/chk-01/` |
| `CHK-02` | `EC-01`, `EC-02`, `SC-01`, `SC-02` | `cd task_generator && bundle exec rspec spec/requests/generation_requests_spec.rb` | JSON-контракт `SUCCESS/ERROR` соответствует правилам | `artifacts/ft-003/verify/chk-02/` |
| `CHK-03` | `EC-03`, `SC-03`, `SC-04`, `NEG-02` | `cd task_generator && bundle exec rspec spec/requests/tasks_spec.rb spec/system/generation_request_flow_spec.rb` | Reopen работает, ошибки `E302/E303` предсказуемы | `artifacts/ft-003/verify/chk-03/` |

### Test matrix

| Check ID | Evidence IDs | Evidence path |
| --- | --- | --- |
| `CHK-01` | `EVID-01` | `artifacts/ft-003/verify/chk-01/` |
| `CHK-02` | `EVID-02` | `artifacts/ft-003/verify/chk-02/` |
| `CHK-03` | `EVID-03` | `artifacts/ft-003/verify/chk-03/` |

### Evidence

- `EVID-01` Логи сервисных тестов оркестрации `BuildDescriptionService` + `SubmitService`.
- `EVID-02` Логи request-тестов контракта `POST /generation_requests`.
- `EVID-03` Логи request/system тестов `GET /task/:id` и reopen-потока.

### Evidence contract

| Evidence ID | Artifact | Producer | Path contract | Reused by checks |
| --- | --- | --- | --- | --- |
| `EVID-01` | RSpec output (services) | verify-runner | `artifacts/ft-003/verify/chk-01/` | `CHK-01` |
| `EVID-02` | RSpec output (generation_requests requests) | verify-runner | `artifacts/ft-003/verify/chk-02/` | `CHK-02` |
| `EVID-03` | RSpec output (tasks requests/system) | verify-runner | `artifacts/ft-003/verify/chk-03/` | `CHK-03` |
