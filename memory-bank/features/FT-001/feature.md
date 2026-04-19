---
title: "FT-001: Выбор навыка и темы перед генерацией задачи"
doc_kind: feature
doc_function: canonical
purpose: "Canonical-документ фичи обязательного ввода `skill/topic` перед запуском генерации задачи."
derived_from:
  - ../../domain/problem.md
  - ../../prd/PRD-001-task-generator-mvp.md
status: done
delivery_status: archived
audience: humans_and_agents
must_not_define:
  - implementation_sequence
---

# FT-001: Выбор навыка и темы перед генерацией задачи

## What

### Problem

Сейчас пользователь не может пройти первый шаг сценария генерации задачи, потому что отсутствует обязательный ввод `skill` и `topic`. Это блокирует запуск MVP-потока и сбор обратной связи.

Источник постановки:
- Brief: исходная документация в `.memory_bank/features/001/brief.md`.
- Tracker: [Issue #3](https://github.com/dan-abramov/ai-setup/issues/3).

### Outcome

| Metric ID | Metric | Baseline | Target | Measurement method |
| --- | --- | --- | --- | --- |
| `MET-01` | Доля пользователей, которые могут указать `skill/topic` и перейти к следующему шагу | `0%` | `100%` | Request/system тесты + ручной smoke сценария формы |

### Scope

- `REQ-01` Добавить форму с двумя обязательными полями: `Навык` (`skill`) и `Тема` (`topic`).
- `REQ-02` Применять нормализацию `strip_tags + trim` и валидацию по каноническому правилу `^(?!\W*$).{1,100}$` для обоих полей.
- `REQ-03` Блокировать переход к следующему шагу при ошибках `E001-E007`; показывать сообщения ошибок в нужной зоне UI.
- `REQ-04` При успешном submit передавать оба значения (`skill`, `topic`) в следующий шаг без потери данных.

### Non-Scope

- `NS-01` Не менять логику генерации самой задачи.
- `NS-02` Не добавлять историю, аналитику, рекомендации и персонализацию.
- `NS-03` Не расширять фичу на языки программирования, кроме Ruby.

### Constraints / Assumptions

- `ASM-01` Базовый пользовательский поток MVP уже предполагает шаг после ввода `skill/topic`, куда можно передать значения.
- `CON-01` Не добавлять новые gem-зависимости без согласования.
- `CON-02` Следовать паттернам MVC и service objects.
- `CON-03` Не изменять файлы вне проекта `ai-setup`.

## How

### Solution

Ввести отдельный этап ввода `skill/topic` с двойной валидацией (клиент + сервер), оркестрировать submit через service object и разрешать переход на следующий шаг только после успешного сохранения валидных значений.

### Change Surface

| Surface | Type | Why it changes |
| --- | --- | --- |
| `task_generator/db/migrate/*_create_generation_requests.rb` | data | Хранение нормализованных `skill/topic` |
| `task_generator/app/models/generation_request.rb` | code | Каноническая нормализация и валидации `E001-E006` |
| `task_generator/app/services/generation_requests/submit_service.rb` | code | Оркестрация submit и маппинг серверной ошибки `E007` |
| `task_generator/app/controllers/generation_requests_controller.rb` | code | HTTP-контракт шага и блокировка невалидного перехода |
| `task_generator/app/views/generation_requests/new.html.erb` | code | Форма, вывод ошибок и управление состояниями |
| `task_generator/app/javascript/controllers/generation_request_form_controller.js` | code | Клиентская state machine `EMPTY/ERROR/READY/LOADING` |
| `task_generator/app/controllers/generation_flow_controller.rb` | code | Следующий шаг-приёмник для успешного перехода |
| `task_generator/config/locales/ru.yml` | config | Тексты ошибок `E001-E007` |
| `task_generator/spec/**` | code | Автотесты модели, сервиса, request и system уровней |
| `task_generator/README.md` | doc | Публичное описание пользовательского шага |

### Flow

1. Пользователь открывает форму и вводит `skill/topic`.
2. Клиент применяет нормализацию и валидацию; при ошибках показывает `E001-E006` и блокирует submit.
3. При валидном submit сервер вызывает `GenerationRequests::SubmitService`, сохраняет запрос и возвращает результат.
4. При `2xx` происходит переход на следующий шаг с переданными `skill/topic`; при 5xx/timeout показывается `E007`.

### Contracts

| Contract ID | Input / Output | Producer / Consumer | Notes |
| --- | --- | --- | --- |
| `CTR-01` | `POST /generation_requests` принимает `skill`, `topic` | UI form -> `GenerationRequestsController` | Входные поля проходят нормализацию до валидации |
| `CTR-02` | Ошибки `E001-E006` маппятся на поля, `E007` на общий alert | Controller/service -> UI | При ошибке значения формы не теряются |
| `CTR-03` | Успех передаёт `skill/topic` в следующий шаг | `SubmitService` -> `GenerationFlowController` | Переход разрешён только при валидных значениях |

### Failure Modes

- `FM-01` Невалидный ввод (пусто, некорректный формат, >100 символов) приводит к `E001-E006` и блокирует переход.
- `FM-02` Исключение/таймаут при submit приводит к `E007` и разрешает повторную попытку без потери введённых данных.

## Verify

### Exit Criteria

- `EC-01` Пользователь может перейти к следующему шагу только при валидных `skill/topic`.
- `EC-02` При невалидном вводе UI показывает корректный код ошибки `E001-E006` у нужного поля.
- `EC-03` При серверной ошибке показывается `E007`, а данные формы сохраняются.

### Traceability matrix

| Requirement ID | Design refs | Acceptance refs | Checks | Evidence IDs |
| --- | --- | --- | --- | --- |
| `REQ-01` | `CON-02`, `CTR-01` | `EC-01`, `SC-01` | `CHK-01`, `CHK-02` | `EVID-01`, `EVID-02` |
| `REQ-02` | `CTR-01`, `FM-01` | `EC-01`, `SC-02`, `NEG-01`, `NEG-02` | `CHK-01` | `EVID-01` |
| `REQ-03` | `CTR-02`, `FM-01`, `FM-02` | `EC-02`, `EC-03`, `SC-02`, `SC-03` | `CHK-01`, `CHK-02` | `EVID-01`, `EVID-02` |
| `REQ-04` | `CTR-03` | `EC-01`, `SC-01` | `CHK-01`, `CHK-02` | `EVID-01`, `EVID-02` |

### Acceptance Scenarios

- `SC-01` Пользователь вводит валидные `skill/topic`, нажимает `Сгенерировать`, получает переход на следующий шаг, где отображаются оба значения.
- `SC-02` Пользователь оставляет поле пустым или вводит невалидный текст; UI показывает соответствующий код `E001-E006`, переход недоступен.
- `SC-03` При ответе сервера `5xx/timeout` UI показывает `E007`, сохраняет значения полей и позволяет повторить submit.

### Negative / Edge Scenarios

- `NEG-01` После нормализации значение состоит только из пробелов/символов пунктуации -> ошибка формата и блокировка перехода.
- `NEG-02` После нормализации длина `skill` или `topic` больше 100 символов -> ошибка формата и блокировка перехода.

### Checks

| Check ID | Covers | How to check | Expected result | Evidence path |
| --- | --- | --- | --- | --- |
| `CHK-01` | `EC-01`, `EC-02`, `SC-01`, `SC-02`, `NEG-01`, `NEG-02` | `cd task_generator && bundle exec rspec spec/models/generation_request_spec.rb spec/services/generation_requests/submit_service_spec.rb spec/requests/generation_requests_spec.rb` | Все проверки зелёные, маппинг `E001-E007` корректный | `artifacts/ft-001/verify/chk-01/` |
| `CHK-02` | `EC-03`, `SC-03` | `cd task_generator && bundle exec rspec spec/system/generation_request_flow_spec.rb` + ручной smoke submit/timeout | UI сохраняет значения и показывает `E007` | `artifacts/ft-001/verify/chk-02/` |

### Test matrix

| Check ID | Evidence IDs | Evidence path |
| --- | --- | --- |
| `CHK-01` | `EVID-01` | `artifacts/ft-001/verify/chk-01/` |
| `CHK-02` | `EVID-02` | `artifacts/ft-001/verify/chk-02/` |

### Evidence

- `EVID-01` Лог выполнения unit/request тестов для `GenerationRequest` и submit-сервиса.
- `EVID-02` Лог system/smoke проверки перехода и обработки `E007`.

### Evidence contract

| Evidence ID | Artifact | Producer | Path contract | Reused by checks |
| --- | --- | --- | --- | --- |
| `EVID-01` | RSpec output (model/service/request) | verify-runner | `artifacts/ft-001/verify/chk-01/` | `CHK-01` |
| `EVID-02` | System test output + smoke notes | verify-runner / human | `artifacts/ft-001/verify/chk-02/` | `CHK-02` |
