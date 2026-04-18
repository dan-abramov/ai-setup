---
title: "FT-002: Генерация краткого описания задачи перед переходом к решению"
doc_kind: feature
doc_function: canonical
purpose: "Canonical-документ фичи генерации `task_description` по `skill/topic` с контрактом ошибок и переходом к решению."
derived_from:
  - ../../domain/problem.md
  - ../../prd/PRD-001-task-generator-mvp.md
status: done
delivery_status: archived
audience: humans_and_agents
must_not_define:
  - implementation_sequence
---

# FT-002: Генерация краткого описания задачи перед переходом к решению

## What

### Problem

После ввода `skill/topic` пользователь не получает задачу для решения, поэтому фактический переход к решению равен `0%`.

Источник постановки:
- Brief: исходная документация в `.memory_bank/features/002/brief.md`.
- Tracker: [Issue #5](https://github.com/dan-abramov/ai-setup/issues/5).

### Outcome

| Metric ID | Metric | Baseline | Target | Measurement method |
| --- | --- | --- | --- | --- |
| `MET-01` | Доля пользователей, перешедших к решению после ввода `skill/topic` | `0%` | `>=80%` к 1 мая 2026 | Product analytics по пользовательскому шагу |
| `MET-02` | Success rate валидных запросов генерации | не зафиксирован | `>=95%` | Метрика по последним 200 валидным запросам |
| `MET-03` | Latency submit -> `SUCCESS` (p95) | не зафиксирован | `<=1s` | Метрика по последним 200 валидным запросам |

### Scope

- `REQ-01` Для валидного `skill/topic` генерировать `task_description` и возвращать `SUCCESS`.
- `REQ-02` Проверять `task_description` после `strip_tags + trim`: длина `1..150`, наличие `topic` (case-insensitive), `skill` (case-insensitive), фразы `Реши через`.
- `REQ-03` Поддерживать состояния `EMPTY/LOADING/SUCCESS/ERROR` и retry только для `E204-E209`.
- `REQ-04` На `SUCCESS` разрешать переход к решению по `generation_request_id`.
- `REQ-05` Предоставить endpoint метрик окна 200 валидных запросов для проверки `p95` и `success_rate`.

### Non-Scope

- `NS-01` Не менять логику проверки пользовательского решения.
- `NS-02` Не менять генерацию автотестов пользовательского решения.
- `NS-03` Не добавлять рекомендации навыков/тем, персонализацию и историю запросов.

### Constraints / Assumptions

- `ASM-01` Входные `skill/topic` уже нормализуются и валидируются как `1..100` на текущем шаге формы.
- `CON-01` Не добавлять новые gem-зависимости без согласования.
- `CON-02` Использовать service objects и текущий Rails стек.
- `CON-03` Не выходить за модульные границы: `BuildDescriptionService`, `DescriptionValidator`, `GenerationFlow`.
- `CON-04` Для AI-вызова использовать `Net::HTTP` и OpenRouter с primary/fallback моделями.

## How

### Solution

Построить pipeline `submit -> generate -> validate -> persist`, где `BuildDescriptionService` управляет состоянием запроса, `DescriptionValidator` гарантирует инварианты результата, а HTTP/UI слой явно следует state machine и контракту кодов `E201-E209`.

### Change Surface

| Surface | Type | Why it changes |
| --- | --- | --- |
| `task_generator/db/migrate/*_add_generation_result_fields_to_generation_requests.rb` | data | Поля результата генерации (`task_description`, `status`, `error_code`, `latency_ms`) |
| `task_generator/app/models/generation_request.rb` | code | Контракт `valid request`, ошибки `E201-E203` |
| `task_generator/config/initializers/generation.rb` | config | Конфигурация OpenRouter и timeout |
| `task_generator/app/services/generation/ai_client.rb` | code | Вызов provider c primary/fallback и таймаутами |
| `task_generator/app/services/generation/description_validator.rb` | code | Проверка инвариантов результата `E206-E209` |
| `task_generator/app/services/generation/build_description_service.rb` | code | Оркестрация pipeline и статусной модели |
| `task_generator/app/controllers/generation_requests_controller.rb` | code | JSON-контракт `POST /generation_requests` |
| `task_generator/app/controllers/generation_flow_controller.rb` | code | Guard `GET /generation_flow/:id` + метрики |
| `task_generator/app/javascript/controllers/generation_request_form_controller.js` | code | Клиентская state machine и retry правила |
| `task_generator/spec/**` | code | Unit/service/request/system покрытие AC-01..AC-08 |
| `task_generator/README.md` | doc | Публичный контракт API и сценария |

### Flow

1. Пользователь отправляет валидные `skill/topic`.
2. `BuildDescriptionService` валидирует вход и создаёт `GenerationRequest` только для валидного запроса.
3. `AiClient` запрашивает OpenRouter (primary -> fallback), затем `DescriptionValidator` проверяет результат.
4. На `SUCCESS` возвращается `task_description` и разрешается переход к решению; на `ERROR` возвращается код `E201-E209` и UI действует по retry-правилам.

### Contracts

| Contract ID | Input / Output | Producer / Consumer | Notes |
| --- | --- | --- | --- |
| `CTR-01` | `POST /generation_requests` -> `200 { state: "SUCCESS", generation_request_id, task_description }` | `GenerationRequestsController` -> frontend | Только для валидной и успешно проверенной генерации |
| `CTR-02` | `POST /generation_requests` -> `422 { state: "ERROR", error_code, generation_request_id? }` | `GenerationRequestsController` -> frontend | Для `E201-E203` id отсутствует; для `E204-E209` id присутствует |
| `CTR-03` | `GET /generation_flow/:id` | `GenerationFlowController` -> browser | Доступ только при `status=SUCCESS` и непустом `task_description` |
| `CTR-04` | `GET /generation_flow/metrics` -> JSON метрики окна 200 запросов | `GenerationFlowController` -> verify tooling | Используется для проверки `MET-02`, `MET-03` |

### Failure Modes

- `FM-01` Вход невалиден (`E201-E203`) -> запись `generation_requests` не создаётся.
- `FM-02` Provider timeout/ошибка (`E204-E205`) -> `ERROR`, доступен retry.
- `FM-03` Генерированный текст нарушает инварианты (`E206-E209`) -> `ERROR`, переход к решению запрещён.

## Verify

### Exit Criteria

- `EC-01` Валидный submit возвращает `SUCCESS` и `task_description`, после чего пользователь может перейти к решению.
- `EC-02` Для `E201-E209` API и UI возвращают предсказуемые коды/состояния и корректные retry-правила.
- `EC-03` Метрики окна 200 валидных запросов показывают `p95 <= 1s` и success rate `>=95%`.

### Traceability matrix

| Requirement ID | Design refs | Acceptance refs | Checks | Evidence IDs |
| --- | --- | --- | --- | --- |
| `REQ-01` | `CTR-01`, `FM-01` | `EC-01`, `SC-01` | `CHK-01`, `CHK-02` | `EVID-01`, `EVID-02` |
| `REQ-02` | `CTR-02`, `FM-03` | `EC-02`, `SC-03`, `NEG-02` | `CHK-01`, `CHK-02` | `EVID-01`, `EVID-02` |
| `REQ-03` | `CTR-02`, `FM-01`, `FM-02`, `FM-03` | `EC-02`, `SC-02`, `SC-03`, `NEG-01` | `CHK-02`, `CHK-03` | `EVID-02`, `EVID-03` |
| `REQ-04` | `CTR-01`, `CTR-03` | `EC-01`, `SC-01` | `CHK-02` | `EVID-02` |
| `REQ-05` | `CTR-04` | `EC-03`, `SC-04` | `CHK-03` | `EVID-03` |

### Acceptance Scenarios

- `SC-01` Валидный запрос возвращает `200 SUCCESS` с `generation_request_id` и `task_description`, затем пользователь проходит в шаг решения.
- `SC-02` При таймауте/ошибке provider (`E204-E205`) API возвращает `422 ERROR`, UI остаётся в `ERROR`, доступна кнопка `Повторить`.
- `SC-03` При невалидном результате генерации (`E206-E209`) API возвращает `422 ERROR`, переход к решению запрещён.
- `SC-04` Endpoint метрик на окне 200 валидных запросов возвращает `p95` и `success_rate`, удовлетворяющие целевым порогам.

### Negative / Edge Scenarios

- `NEG-01` При `E201-E203` не создаётся `GenerationRequest`, `generation_request_id` отсутствует в ответе.
- `NEG-02` Если результат длиннее 150 или не содержит `topic/skill/фразу`, возвращается один из `E206-E209`.

### Checks

| Check ID | Covers | How to check | Expected result | Evidence path |
| --- | --- | --- | --- | --- |
| `CHK-01` | `EC-01`, `EC-02`, `SC-01`, `SC-02`, `SC-03`, `NEG-01`, `NEG-02` | `cd task_generator && bundle exec rspec spec/models spec/services` | Сервисы/валидаторы и маппинг ошибок `E201-E209` проходят | `artifacts/ft-002/verify/chk-01/` |
| `CHK-02` | `EC-01`, `EC-02`, `SC-01`, `SC-02`, `SC-03` | `cd task_generator && bundle exec rspec spec/requests spec/system` | HTTP/UI контракт соответствует состояниям и retry-правилам | `artifacts/ft-002/verify/chk-02/` |
| `CHK-03` | `EC-03`, `SC-04` | request-smoke `GET /generation_flow/metrics` на окне >=200 валидных запросов | `p95 <= 1s`, `success_rate >=95%` | `artifacts/ft-002/verify/chk-03/` |

### Test matrix

| Check ID | Evidence IDs | Evidence path |
| --- | --- | --- |
| `CHK-01` | `EVID-01` | `artifacts/ft-002/verify/chk-01/` |
| `CHK-02` | `EVID-02` | `artifacts/ft-002/verify/chk-02/` |
| `CHK-03` | `EVID-03` | `artifacts/ft-002/verify/chk-03/` |

### Evidence

- `EVID-01` Логи unit/service тестов (`GenerationRequest`, `AiClient`, `DescriptionValidator`, `BuildDescriptionService`).
- `EVID-02` Логи request/system тестов контракта `POST /generation_requests` и UI state machine.
- `EVID-03` JSON/лог проверки endpoint метрик и расчёта `p95/success_rate`.

### Evidence contract

| Evidence ID | Artifact | Producer | Path contract | Reused by checks |
| --- | --- | --- | --- | --- |
| `EVID-01` | RSpec output (unit/service) | verify-runner | `artifacts/ft-002/verify/chk-01/` | `CHK-01` |
| `EVID-02` | RSpec output (request/system) | verify-runner | `artifacts/ft-002/verify/chk-02/` | `CHK-02` |
| `EVID-03` | Metrics snapshot and verify notes | verify-runner / human | `artifacts/ft-002/verify/chk-03/` | `CHK-03` |
