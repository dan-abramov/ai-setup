---
title: "FT-012: Сохранять код-решение задачи, введенный пользователем"
doc_kind: feature
doc_function: canonical
purpose: "Canonical-документ фичи сохранения пользовательского `solution_code` для задачи и повторного показа на `/task/:id`."
derived_from:
  - ../../domain/problem.md
  - ../../prd/PRD-001-task-generator-mvp.md
status: active
delivery_status: planned
audience: humans_and_agents
must_not_define:
  - implementation_sequence
---

# FT-012: Сохранять код-решение задачи, введенный пользователем

## What

### Problem

В issue [#12](https://github.com/dan-abramov/ai-setup/issues/12) поставлена задача: сохранять код-решение, введенное пользователем.

Сейчас на `/task/:id` есть editable поле `solution_code`, но оно UI-only: после перезагрузки страницы или повторного открытия задачи по URL введенный код теряется.

Источник постановки:

- Tracker: [Issue #12](https://github.com/dan-abramov/ai-setup/issues/12).
- Body issue отсутствует (`body: null`), поэтому в документе явно зафиксированы assumptions по UX сохранения.

### Outcome

| Metric ID | Metric                                                                      | Baseline | Target                              | Measurement method          |
| --------- | --------------------------------------------------------------------------- | -------- | ----------------------------------- | --------------------------- |
| `MET-01`  | Доля reopen-сценариев `/task/:id`, где ранее сохраненный `solution_code` восстановлен | `0%`     | `100%` для задач с сохраненным кодом | request/system тесты + smoke |
| `MET-02`  | Число задач, для которых доступно persistence пользовательского решения      | `0`      | `>= 1` (любая валидная `Task`)      | model/request coverage      |

### Scope

- `REQ-01` Добавить persistence пользовательского `solution_code` на уровне `Task`.
- `REQ-02` Добавить серверный контракт сохранения `solution_code` для существующей задачи (`/task/:id`) без изменения generation API.
- `REQ-03` На `GET /task/:id` предзаполнять поле `solution_code` последним сохраненным значением.
- `REQ-04` Поддержать обновление и очистку ранее сохраненного `solution_code` в рамках того же UI-потока.
- `REQ-05` Обновить тесты и документацию под новый контракт сохранения.

### Non-Scope

- `NS-01` Не реализовывать проверку/исполнение пользовательского кода и вердикт решения.
- `NS-02` Не добавлять историю версий решения, diff-режим или multi-draft хранилище.
- `NS-03` Не добавлять autosave на каждый ввод символа в рамках FT-012.
- `NS-04` Не менять error-contract `E201-E209`, `E301-E303` и существующий JSON-контракт `POST /generation_requests`.

### Constraints / Assumptions

- `ASM-01` Из-за отсутствия body issue минимальный UX-контракт трактуется как явное сохранение через action на странице задачи (без обязательного autosave).
- `ASM-02` Для каждой `Task` хранится одно актуальное текстовое значение `solution_code`.
- `ASM-03` Пустое значение при сохранении трактуется как очистка ранее сохраненного решения.
- `CON-01` Нельзя добавлять новые gem-зависимости.
- `CON-02` Не выходить за границы проекта `ai-setup`.
- `CON-03` `GET /task/:id` продолжает соблюдать текущий контракт ошибок (`E302`/`E303`).

## How

### Solution

Добавить поле `solution_code` в `tasks`, расширить `tasks#show` UI до формы с явным сохранением и добавить update-контракт для записи/очистки решения. После успешного сохранения страница задачи должна отображать последнее сохраненное значение без изменения generation/reopen контрактов.

### Change Surface

| Surface | Type | Why it changes |
| ------- | ---- | -------------- |
| `task_generator/db/migrate/*_add_solution_code_to_tasks.rb` | code | Добавление persistent поля `solution_code` в таблицу `tasks` |
| `task_generator/db/schema.rb` | code | Фиксация обновленной схемы после миграции |
| `task_generator/app/models/task.rb` | code | Валидации/нормализация (если требуется) для `solution_code` |
| `task_generator/config/routes.rb` | code | Добавление маршрута сохранения решения для `/task/:id` |
| `task_generator/app/controllers/tasks_controller.rb` | code | Реализация action сохранения `solution_code` и обработка ошибок |
| `task_generator/app/views/tasks/show.html.erb` | code | Форма сохранения и предзаполнение поля сохраненным значением |
| `task_generator/config/locales/ru.yml` | code | Тексты кнопки/подсказок/сообщений результата сохранения |
| `task_generator/spec/models/task_spec.rb` | code | Проверка model-контракта хранения `solution_code` |
| `task_generator/spec/requests/tasks_spec.rb` | code | Проверка HTTP-контракта сохранения и неизменности reopen ошибок |
| `task_generator/spec/system/generation_request_flow_spec.rb` | code | Сквозной сценарий ввода -> сохранения -> повторного открытия задачи |
| `task_generator/README.md` | doc | Синхронизация публичного пользовательского контракта |

### Flow

1. Пользователь открывает `/task/:id`, видит описание задачи и поле `solution_code`.
2. Вводит или редактирует код-решение.
3. Явно инициирует сохранение на странице задачи.
4. Сервер сохраняет значение в `Task`.
5. При следующем открытии `/task/:id` поле предзаполнено сохраненным кодом.

### Contracts

| Contract ID | Input / Output | Producer / Consumer | Notes |
| ----------- | -------------- | ------------------- | ----- |
| `CTR-01` | `Task` хранит `solution_code:text` | ActiveRecord model -> DB | Одно актуальное значение на задачу |
| `CTR-02` | HTTP action сохранения принимает `solution_code` и возвращает пользователя на `/task/:id` | `TasksController` -> browser | Сценарий update/clear работает без изменения generation API |
| `CTR-03` | `GET /task/:id` рендерит сохраненный `solution_code` в editable поле | `tasks/show` -> user | Значение переживает refresh/reopen |
| `CTR-04` | `POST /generation_requests` и коды `E201-E209`, `E301-E303` остаются совместимыми | Generation flow -> frontend | FT-012 не вносит API-дельту generation endpoint |

### Failure Modes

- `FM-01` Пользовательский код не сохраняется из-за отсутствия route/strong params/update action.
- `FM-02` Сохранение решения ломает существующий контракт `GET /task/:id` по `E302/E303`.
- `FM-03` Введенный код рендерится небезопасно (HTML-инъекции) вместо экранированного текста.
- `FM-04` Очистка решения (`""`) не применяется и оставляет stale-значение.

## Verify

### Exit Criteria

- `EC-01` Сохраненный `solution_code` восстанавливается после refresh/reopen `/task/:id`.
- `EC-02` Пользователь может обновить и очистить сохраненный `solution_code`.
- `EC-03` Generation/reopen контракты остаются совместимыми.

### Traceability matrix

| Requirement ID | Design refs | Acceptance refs | Checks | Evidence IDs |
| -------------- | ----------- | --------------- | ------ | ------------ |
| `REQ-01` | `ASM-02`, `CTR-01` | `EC-01`, `SC-01`, `SC-02` | `CHK-01`, `CHK-02` | `EVID-01`, `EVID-02` |
| `REQ-02` | `CTR-02`, `FM-01` | `EC-01`, `SC-01`, `NEG-01` | `CHK-01` | `EVID-01` |
| `REQ-03` | `CTR-03`, `FM-03` | `EC-01`, `SC-02`, `NEG-02` | `CHK-02`, `CHK-03` | `EVID-02`, `EVID-03` |
| `REQ-04` | `ASM-03`, `FM-04` | `EC-02`, `SC-03`, `NEG-03` | `CHK-01`, `CHK-03` | `EVID-01`, `EVID-03` |
| `REQ-05` | `CON-03`, `CTR-04` | `EC-03`, `SC-04` | `CHK-01`, `CHK-02` | `EVID-01`, `EVID-02` |

### Acceptance Scenarios

- `SC-01` На `/task/:id` пользователь вводит код и сохраняет его; после reload значение остается в поле.
- `SC-02` Пользователь повторно открывает ту же задачу по URL и видит ранее сохраненный `solution_code`.
- `SC-03` Пользователь очищает поле и сохраняет; после reload поле остается пустым.
- `SC-04` Существующие generation/reopen сценарии продолжают работать без изменения кодов ошибок.

### Negative / Edge Scenarios

- `NEG-01` Попытка сохранить решение для несуществующей задачи не приводит к `500` и соблюдает not-found контракт.
- `NEG-02` Ввод с символами `<`, `>`, `'`, `"` отображается как текст и не исполняется как HTML/JS.
- `NEG-03` Очистка ранее сохраненного значения (`solution_code = ""`) не оставляет stale-данных.

### Checks

| Check ID | Covers | How to check | Expected result | Evidence path |
| -------- | ------ | ------------ | --------------- | ------------- |
| `CHK-01` | `EC-01`, `EC-02`, `SC-01`, `SC-03`, `NEG-01`, `NEG-03` | `cd task_generator && bundle exec rspec spec/requests/tasks_spec.rb spec/models/task_spec.rb` | Контракт сохранения/очистки работает, model/request уровень стабилен | `artifacts/ft-012/verify/chk-01/` |
| `CHK-02` | `EC-01`, `EC-03`, `SC-02`, `SC-04`, `NEG-02` | `cd task_generator && bundle exec rspec spec/system/generation_request_flow_spec.rb` | Сквозной flow подтверждает persistence и отсутствие регрессий | `artifacts/ft-012/verify/chk-02/` |
| `CHK-03` | `EC-02`, `SC-02`, `SC-03` | Ручной smoke: открыть `/task/:id`, сохранить код, перезагрузить страницу, очистить и сохранить снова | UX сохранения/очистки предсказуем и соответствует контракту | `artifacts/ft-012/verify/chk-03/` |

### Test matrix

| Check ID | Evidence IDs | Evidence path |
| -------- | ------------ | ------------- |
| `CHK-01` | `EVID-01` | `artifacts/ft-012/verify/chk-01/` |
| `CHK-02` | `EVID-02` | `artifacts/ft-012/verify/chk-02/` |
| `CHK-03` | `EVID-03` | `artifacts/ft-012/verify/chk-03/` |

### Evidence

- `EVID-01` Логи model/request тестов по контракту сохранения `solution_code`.
- `EVID-02` Логи system-теста по сценарию reopen с сохраненным кодом.
- `EVID-03` Краткий manual smoke-отчет по сохранению и очистке.

### Evidence contract

| Evidence ID | Artifact | Producer | Path contract | Reused by checks |
| ----------- | -------- | -------- | ------------- | ---------------- |
| `EVID-01` | RSpec output (model + requests) | verify-runner | `artifacts/ft-012/verify/chk-01/` | `CHK-01` |
| `EVID-02` | RSpec output (system) | verify-runner | `artifacts/ft-012/verify/chk-02/` | `CHK-02` |
| `EVID-03` | Smoke notes | verify-runner / human | `artifacts/ft-012/verify/chk-03/` | `CHK-03` |
