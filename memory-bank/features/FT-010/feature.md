---
title: "FT-010: Убрать отображение статуса генерации request в пользовательских view"
doc_kind: feature
doc_function: canonical
purpose: "Canonical-документ фичи удаления визуального статуса generation request из UI без изменения backend-контрактов."
derived_from:
  - ../../domain/problem.md
  - ../../prd/PRD-001-task-generator-mvp.md
status: active
delivery_status: done
audience: humans_and_agents
must_not_define:
  - implementation_sequence
---

# FT-010: Убрать отображение статуса генерации request в пользовательских view

## What

### Problem

В issue [#10](https://github.com/dan-abramov/ai-setup/issues/10) поставлена задача: убрать статус генерации request на view-слое.

Сейчас форма генерации показывает статусный бейдж (`EMPTY/LOADING/SUCCESS/ERROR`). Это добавляет лишний UI-шум и не является обязательной частью пользовательского контракта, где основная ценность — получение задачи или понятного кода ошибки.

Источник постановки:

- Tracker: [Issue #10](https://github.com/dan-abramov/ai-setup/issues/10).
- Body issue отсутствует (`body: null`), поэтому в документе явно зафиксированы assumptions.

### Outcome


| Metric ID | Metric                                                                       | Baseline                            | Target                              | Measurement method                 |
| --------- | ---------------------------------------------------------------------------- | ----------------------------------- | ----------------------------------- | ---------------------------------- |
| `MET-01`  | Число пользовательских view, где явно отображается статус generation request | `>= 1` (`/generation_requests/new`) | `0`                                 | View review + system smoke         |
| `MET-02`  | Сохранение работоспособности submit/retry сценария после удаления статуса    | не зафиксирован отдельно            | `100%` критичных сценариев проходят | `spec/system` + request/regression |


### Scope

- `REQ-01` Убрать явное отображение статуса generation request (`EMPTY/LOADING/SUCCESS/ERROR`) из user-facing view.
- `REQ-02` Сохранить существующий поведенческий контракт submit/retry: успешная генерация ведет на `/task/:id`, ошибки показываются через `error_code`.
- `REQ-03` Удалить или адаптировать front-end привязки к DOM-элементу статусного бейджа так, чтобы не возникало JS-ошибок.
- `REQ-04` Обновить тесты и документацию под новый UI-контракт.

### Non-Scope

- `NS-01` Не менять модель `GenerationRequest` и ее `status` в БД.
- `NS-02` Не менять API-контракты `POST /generation_requests`, `GET /task/:id`, `GET /generation_flow/*`.
- `NS-03` Не менять набор и семантику кодов ошибок `E201-E209`, `E301-E303`.

### Constraints / Assumptions

- `ASM-01` Под задачей из issue понимается именно удаление визуального статуса, а не отказ от внутренней state machine фронтенда.
- `ASM-02` User-facing view в рамках фичи: `generation_requests/new`, `generation_flow/show`, `tasks/show`.
- `CON-01` Нельзя добавлять новые gem-зависимости.
- `CON-02` Не выходить за границы проекта `ai-setup`.
- `CON-03` Изменения должны сохранить обратную совместимость текущих request/system тестов или явно обновить ожидаемое поведение.

## How

### Solution

Убрать UI-элемент отображения статуса generation request и адаптировать Stimulus-контроллер так, чтобы внутреннее состояние продолжало управлять логикой кнопок и ошибок, но не выводилось пользователю как отдельный статусный текст/бейдж.

### Change Surface


| Surface                                                                           | Type | Why it changes                                                             |
| --------------------------------------------------------------------------------- | ---- | -------------------------------------------------------------------------- |
| `task_generator/app/views/generation_requests/new.html.erb`                       | code | Удаление status-badge блока и связанных data-target                        |
| `task_generator/app/javascript/controllers/generation_request_form_controller.js` | code | Удаление зависимости от `stateLabelTarget`, сохранение state-driven логики |
| `task_generator/app/assets/stylesheets/application.css`                           | code | Удаление/адаптация стилей статуса, если остаются неиспользуемыми           |
| `task_generator/spec/system/generation_request_flow_spec.rb`                      | code | Обновление ожиданий UI под отсутствие статусного бейджа                    |
| `task_generator/spec/requests/generation_requests_spec.rb`                        | code | Regression-проверка: API-контракт не изменился                             |
| `task_generator/README.md`                                                        | doc  | Синхронизация UI-описания и контракта                                      |


### Flow

1. Пользователь открывает `/generation_requests/new` и видит форму без отдельного текстового статуса генерации.
2. При submit UI блокирует повторную отправку и управляет ошибками/retry по внутреннему состоянию.
3. При `SUCCESS` выполняется redirect на `/task/:id`.
4. При `ERROR` показывается `error_code` и, для retryable ошибок, кнопка повтора.

### Contracts


| Contract ID | Input / Output                                              | Producer / Consumer        | Notes                                                |
| ----------- | ----------------------------------------------------------- | -------------------------- | ---------------------------------------------------- |
| `CTR-01`    | UI больше не показывает отдельный статус generation request | View/Stimulus -> user      | Внутреннее состояние остаётся техническим механизмом |
| `CTR-02`    | `POST /generation_requests` JSON-контракт без изменений     | Controller/API -> Stimulus | `state/error_code/task_path` остаются совместимыми   |
| `CTR-03`    | Retry-правила для `E204-E209`, `E301` сохраняются           | Stimulus -> user           | Нельзя деградировать recoverable flow                |


### Failure Modes

- `FM-01` После удаления status target Stimulus-контроллер падает на обращении к отсутствующему элементу.
- `FM-02` Без статусного бейджа пользователь теряет обратную связь во время `LOADING`, и submit/retry UX становится непредсказуемым.
- `FM-03` UI-изменение случайно затрагивает API-контракт или коды ошибок.

## Verify

### Exit Criteria

- `EC-01` На user-facing view нет отдельного визуального статуса generation request.
- `EC-02` Submit/retry flow работает как до изменения.
- `EC-03` API/ошибочные контракты не изменились.

### Traceability matrix


| Requirement ID | Design refs                 | Acceptance refs           | Checks             | Evidence IDs         |
| -------------- | --------------------------- | ------------------------- | ------------------ | -------------------- |
| `REQ-01`       | `ASM-01`, `CTR-01`          | `EC-01`, `SC-01`          | `CHK-01`, `CHK-03` | `EVID-01`, `EVID-03` |
| `REQ-02`       | `CTR-02`, `CTR-03`, `FM-02` | `EC-02`, `SC-02`, `SC-03` | `CHK-01`, `CHK-02` | `EVID-01`, `EVID-02` |
| `REQ-03`       | `FM-01`, `FM-02`            | `EC-02`, `NEG-01`         | `CHK-01`           | `EVID-01`            |
| `REQ-04`       | `CON-03`                    | `EC-03`, `NEG-02`         | `CHK-02`           | `EVID-02`            |


### Acceptance Scenarios

- `SC-01` Пользователь открывает `/generation_requests/new` и не видит статусный бейдж `EMPTY/LOADING/SUCCESS/ERROR`.
- `SC-02` Валидный submit по-прежнему завершает flow и переводит на `/task/:id`.
- `SC-03` При retryable ошибке UI показывает `error_code` и позволяет повторить запрос.

### Negative / Edge Scenarios

- `NEG-01` После удаления status-блока не возникает JS-исключений в Stimulus lifecycle.
- `NEG-02` Request-контракт `POST /generation_requests` не меняется (payload, status codes, error codes).

### Checks


| Check ID | Covers                                                | How to check                                                                                                   | Expected result                                          | Evidence path                     |
| -------- | ----------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------- | --------------------------------- |
| `CHK-01` | `EC-01`, `EC-02`, `SC-01`, `SC-02`, `SC-03`, `NEG-01` | `cd task_generator && bundle exec rspec spec/system/generation_request_flow_spec.rb`                           | UI-flow проходит, status-бейдж отсутствует, JS не падает | `artifacts/ft-010/verify/chk-01/` |
| `CHK-02` | `EC-03`, `NEG-02`                                     | `cd task_generator && bundle exec rspec spec/requests/generation_requests_spec.rb spec/requests/tasks_spec.rb` | API-контракт и reopen flow без регрессий                 | `artifacts/ft-010/verify/chk-02/` |
| `CHK-03` | `EC-01`, `EC-02`                                      | Ручной smoke: открыть форму, отправить валидный запрос, проверить retryable ошибку                             | Поведение соответствует `SC-01..SC-03`                   | `artifacts/ft-010/verify/chk-03/` |


### Test matrix


| Check ID | Evidence IDs | Evidence path                     |
| -------- | ------------ | --------------------------------- |
| `CHK-01` | `EVID-01`    | `artifacts/ft-010/verify/chk-01/` |
| `CHK-02` | `EVID-02`    | `artifacts/ft-010/verify/chk-02/` |
| `CHK-03` | `EVID-03`    | `artifacts/ft-010/verify/chk-03/` |


### Evidence

- `EVID-01` Логи system-теста пользовательского flow без status-бейджа.
- `EVID-02` Логи request-тестов на неизменность контрактов.
- `EVID-03` Краткий smoke-отчёт и скриншот(ы) обновленного UI.

### Evidence contract


| Evidence ID | Artifact                 | Producer              | Path contract                     | Reused by checks |
| ----------- | ------------------------ | --------------------- | --------------------------------- | ---------------- |
| `EVID-01`   | RSpec output (system)    | verify-runner         | `artifacts/ft-010/verify/chk-01/` | `CHK-01`         |
| `EVID-02`   | RSpec output (requests)  | verify-runner         | `artifacts/ft-010/verify/chk-02/` | `CHK-02`         |
| `EVID-03`   | Smoke notes + screenshot | verify-runner / human | `artifacts/ft-010/verify/chk-03/` | `CHK-03`         |
