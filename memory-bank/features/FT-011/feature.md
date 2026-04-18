---

## title: "FT-011: Добавить поле ввода кода-решения на странице задачи"
doc_kind: feature
doc_function: canonical
purpose: "Canonical-документ фичи добавления user-editable input для ввода кода-решения в reopen-потоке `GET /task/:id`."
derived_from:
  - ../../domain/problem.md
  - ../../prd/PRD-001-task-generator-mvp.md
status: active
delivery_status: planned
audience: humans_and_agents
must_not_define:
  - implementation_sequence

# FT-011: Добавить поле ввода кода-решения на странице задачи

## What

### Problem

В issue [#11](https://github.com/dan-abramov/ai-setup/issues/11) поставлена задача: сделать input, в который пользователь сможет писать код-решение к задаче.

Сейчас после генерации и открытия `/task/:id` пользователь видит только `task_description`. Поле для написания собственного кода отсутствует, из-за чего шаг "прочитал задачу -> начал писать решение" происходит вне продукта.

Источник постановки:

- Tracker: [Issue #11](https://github.com/dan-abramov/ai-setup/issues/11).
- Body issue отсутствует (`body: null`), поэтому в документе явно зафиксированы assumptions.

### Outcome


| Metric ID | Metric                                                             | Baseline        | Target                     | Measurement method           |
| --------- | ------------------------------------------------------------------ | --------------- | -------------------------- | ---------------------------- |
| `MET-01`  | Число экранов задачи, где есть editable input для кода-решения     | `0`             | `1` (`/task/:id`)          | View review + system smoke   |
| `MET-02`  | Доля сценариев reopen `GET /task/:id`, где поле доступно для ввода | не зафиксирован | `100%` для валидной задачи | `spec/system` + ручной smoke |


### Scope

- `REQ-01` Добавить на страницу `GET /task/:id` пользовательский input для ввода кода-решения (многострочный).
- `REQ-02` Input должен принимать обычный Ruby-код как текст, включая переносы строк и символы пунктуации, без искажения содержимого при вводе.
- `REQ-03` Новое поле не должно ломать текущий read-only показ `task_description` и reopen-контракт страницы задачи.
- `REQ-04` Обновить тесты и документацию под новый UI-контракт страницы задачи.

### Non-Scope

- `NS-01` Не реализовывать проверку пользовательского кода, запуск тестов и вердикт решения.
- `NS-02` Не добавлять persistence пользовательского решения в БД в рамках FT-011.
- `NS-03` Не менять API-контракт `POST /generation_requests` и error-коды `E201-E209`, `E301-E303`.

### Constraints / Assumptions

- `ASM-01` Под "input" из issue понимается именно поле ввода на `tasks/show` (например, `textarea`) в рамках текущего UI.
- `ASM-02` Поскольку body issue отсутствует, фича трактуется как UI-only шаг для ввода, без backend submit/persist.
- `CON-01` Нельзя добавлять новые gem-зависимости.
- `CON-02` Не выходить за границы проекта `ai-setup`.
- `CON-03` Сохранить текущий reopen flow и обработку ошибок `E302/E303`.

## How

### Solution

Добавить на страницу задачи отдельный блок с многострочным полем ввода пользовательского кода и, при необходимости, минимальной стилизацией. Изменение ограничить view-уровнем и тестами, не затрагивая API и модель данных.

### Change Surface


| Surface                                                      | Type | Why it changes                                                              |
| ------------------------------------------------------------ | ---- | --------------------------------------------------------------------------- |
| `task_generator/app/views/tasks/show.html.erb`               | code | Добавление visible/editable input для кода-решения рядом с описанием задачи |
| `task_generator/app/assets/stylesheets/application.css`      | code | Стилизация нового блока ввода, чтобы сохранить читаемость на desktop/mobile |
| `task_generator/spec/system/generation_request_flow_spec.rb` | code | Проверка, что после генерации и перехода на `/task/:id` поле ввода доступно |
| `task_generator/spec/requests/tasks_spec.rb`                 | code | Regression: reopen-страница и error-коды работают как раньше                |
| `task_generator/README.md`                                   | doc  | Синхронизация описания пользовательского шага решения                       |


### Flow

1. Пользователь генерирует задачу и попадает на `/task/:id`.
2. Страница показывает `task_description` и новое поле для ввода кода-решения.
3. Пользователь пишет код в input; серверные контракты при этом не меняются.

### Contracts


| Contract ID | Input / Output                                                           | Producer / Consumer                        | Notes                                     |
| ----------- | ------------------------------------------------------------------------ | ------------------------------------------ | ----------------------------------------- |
| `CTR-01`    | UI `GET /task/:id` содержит editable поле `solution_code`                | `tasks/show` -> user                       | Поле доступно на валидной странице задачи |
| `CTR-02`    | `GET /task/:id` для невалидных состояний продолжает отдавать `E302/E303` | `TasksController` -> browser               | Новое поле не влияет на error-контракт    |
| `CTR-03`    | `POST /generation_requests` JSON-контракт остается без изменений         | `GenerationRequestsController` -> frontend | FT-011 не вносит API-дельту               |


### Failure Modes

- `FM-01` Поле отображается, но не редактируется из-за неверной разметки/атрибутов.
- `FM-02` Добавление input ломает рендер `task_description` или reopen-страницу.
- `FM-03` Изменения во view случайно затрагивают обработку `E302/E303`.

## Verify

### Exit Criteria

- `EC-01` На `/task/:id` есть editable многострочное поле для кода-решения.
- `EC-02` Пользователь может ввести многострочный текст в новое поле без UI-ошибок.
- `EC-03` Reopen/error контракт `GET /task/:id` и API-контракт submit остаются совместимыми.

### Traceability matrix


| Requirement ID | Design refs                | Acceptance refs            | Checks             | Evidence IDs         |
| -------------- | -------------------------- | -------------------------- | ------------------ | -------------------- |
| `REQ-01`       | `ASM-01`, `CTR-01`         | `EC-01`, `SC-01`           | `CHK-01`, `CHK-03` | `EVID-01`, `EVID-03` |
| `REQ-02`       | `ASM-02`, `FM-01`          | `EC-02`, `SC-02`, `NEG-01` | `CHK-01`, `CHK-03` | `EVID-01`, `EVID-03` |
| `REQ-03`       | `CTR-02`, `FM-02`, `FM-03` | `EC-03`, `SC-03`, `NEG-02` | `CHK-01`, `CHK-02` | `EVID-01`, `EVID-02` |
| `REQ-04`       | `CON-03`                   | `EC-03`                    | `CHK-02`           | `EVID-02`            |


### Acceptance Scenarios

- `SC-01` Пользователь открывает существующую задачу по `/task/:id` и видит отдельное поле ввода кода-решения.
- `SC-02` Пользователь вводит в поле многострочный Ruby-код; текст корректно отображается в процессе ввода.
- `SC-03` Reopen страницы задачи и ошибки `E302/E303` работают без изменения поведения.

### Negative / Edge Scenarios

- `NEG-01` Ввод с символами `<`, `>`, `'`, `"` и переносами строк не ломает UI.
- `NEG-02` `GET /task/:id` для несуществующей/невалидной задачи по-прежнему возвращает ожидаемую ошибку (`E302`/`E303`).

### Checks


| Check ID | Covers                                       | How to check                                                                                                   | Expected result                                                            | Evidence path                     |
| -------- | -------------------------------------------- | -------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------- | --------------------------------- |
| `CHK-01` | `EC-01`, `EC-02`, `SC-01`, `SC-02`, `NEG-01` | `cd task_generator && bundle exec rspec spec/system/generation_request_flow_spec.rb`                           | Система показывает input на `/task/:id`, ввод многострочного кода доступен | `artifacts/ft-011/verify/chk-01/` |
| `CHK-02` | `EC-03`, `SC-03`, `NEG-02`                   | `cd task_generator && bundle exec rspec spec/requests/tasks_spec.rb spec/requests/generation_requests_spec.rb` | Reopen/API контракты без регрессий                                         | `artifacts/ft-011/verify/chk-02/` |
| `CHK-03` | `EC-01`, `EC-02`                             | Ручной smoke: открыть `/task/:id`, ввести Ruby-код в поле, проверить отсутствие UI-сбоев                       | Ввод доступен и UX предсказуемый                                           | `artifacts/ft-011/verify/chk-03/` |


### Test matrix


| Check ID | Evidence IDs | Evidence path                     |
| -------- | ------------ | --------------------------------- |
| `CHK-01` | `EVID-01`    | `artifacts/ft-011/verify/chk-01/` |
| `CHK-02` | `EVID-02`    | `artifacts/ft-011/verify/chk-02/` |
| `CHK-03` | `EVID-03`    | `artifacts/ft-011/verify/chk-03/` |


### Evidence

- `EVID-01` Логи system-теста, подтверждающие рендер и доступность input на странице задачи.
- `EVID-02` Логи request-тестов на неизменность reopen/API-контрактов.
- `EVID-03` Краткий manual smoke-отчет по вводу многострочного кода.

### Evidence contract


| Evidence ID | Artifact                | Producer              | Path contract                     | Reused by checks |
| ----------- | ----------------------- | --------------------- | --------------------------------- | ---------------- |
| `EVID-01`   | RSpec output (system)   | verify-runner         | `artifacts/ft-011/verify/chk-01/` | `CHK-01`         |
| `EVID-02`   | RSpec output (requests) | verify-runner         | `artifacts/ft-011/verify/chk-02/` | `CHK-02`         |
| `EVID-03`   | Smoke notes             | verify-runner / human | `artifacts/ft-011/verify/chk-03/` | `CHK-03`         |


