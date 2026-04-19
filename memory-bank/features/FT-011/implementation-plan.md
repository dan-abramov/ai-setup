---

## title: "FT-011: Implementation Plan"
doc_kind: feature
doc_function: derived
purpose: "Execution-план реализации FT-011: добавить поле ввода кода-решения на `/task/:id` без изменения API/модели."
derived_from:
  - feature.md
status: active
audience: humans_and_agents
must_not_define:
  - ft_011_scope
  - ft_011_architecture
  - ft_011_acceptance_criteria
  - ft_011_blocker_state

# План имплементации

## Цель текущего плана

Добавить на страницу задачи пользовательский input для набора кода-решения так, чтобы сохранить текущие reopen/API контракты и не выйти за UI-only границы FT-011.

## Current State / Reference Points


| Path / module                                                | Current role                                     | Why relevant                                                         | Reuse / mirror                             |
| ------------------------------------------------------------ | ------------------------------------------------ | -------------------------------------------------------------------- | ------------------------------------------ |
| `task_generator/app/views/tasks/show.html.erb`               | Рендер страницы задачи после генерации           | Основная точка добавления input-поля                                 | Сохраняем текущий вывод `task_description` |
| `task_generator/app/controllers/tasks_controller.rb`         | Контракт `GET /task/:id`, ошибки `E302/E303`     | Нужно убедиться, что UI-изменение не ломает поведение контроллера    | Не меняем server-side контракт             |
| `task_generator/app/assets/stylesheets/application.css`      | Общие стили интерфейса                           | Нужна читаемость поля ввода на desktop/mobile                        | Следуем существующим стиль-конвенциям      |
| `task_generator/spec/system/generation_request_flow_spec.rb` | Сквозной сценарий генерации и перехода на задачу | Нужна проверка, что поле появляется в реальном пользовательском flow | Использовать как основной acceptance suite |
| `task_generator/spec/requests/tasks_spec.rb`                 | Request-контракт reopen                          | Regression, что `E302/E303` не деградировали                         | Текущие сценарии должны остаться зелеными  |
| `task_generator/README.md`                                   | Публичное описание пользовательского поведения   | Документация должна отражать новый шаг с input                       | Обновить после прохождения тестов          |


## Test Strategy


| Test surface            | Canonical refs                                  | Existing coverage                                         | Planned automated coverage                                 | Required local suites / commands                                                                               | Required CI suites / jobs | Manual-only gap / justification                  | Manual-only approval ref |
| ----------------------- | ----------------------------------------------- | --------------------------------------------------------- | ---------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- | ------------------------- | ------------------------------------------------ | ------------------------ |
| UI input на `/task/:id` | `REQ-01`, `REQ-02`, `SC-01`, `SC-02`, `CHK-01`  | Есть system flow без проверки поля решения                | Добавить ожидания на наличие и editable-состояние input    | `cd task_generator && bundle exec rspec spec/system/generation_request_flow_spec.rb`                           | system / rspec            | Короткий smoke по вводу многострочного Ruby-кода | `AG-01`                  |
| Reopen/API regression   | `REQ-03`, `REQ-04`, `SC-03`, `NEG-02`, `CHK-02` | Request tests уже покрывают `E302/E303` и submit-контракт | Прогнать существующие request suites без дрейфа контрактов | `cd task_generator && bundle exec rspec spec/requests/tasks_spec.rb spec/requests/generation_requests_spec.rb` | requests / rspec          | none                                             | none                     |


## Open Questions / Ambiguities


| Open Question ID | Question                                                                | Why unresolved                               | Blocks               | Default action / escalation owner                      |
| ---------------- | ----------------------------------------------------------------------- | -------------------------------------------- | -------------------- | ------------------------------------------------------ |
| `OQ-01`          | Нужен ли отдельный submit/check action для введённого кода уже в FT-011 | Issue #11 формулирует только "сделать input" | `STEP-02`, `STEP-05` | По умолчанию реализовать UI-only поле без submit/check |
| `OQ-02`          | Нужно ли сохранять введённый код между перезагрузками страницы          | В issue нет требований к persistence         | `STEP-02`, `STEP-07` | По умолчанию не добавлять persistence в рамках FT-011  |


## Environment Contract


| Area                       | Contract                                                     | Used by              | Failure symptom                                      |
| -------------------------- | ------------------------------------------------------------ | -------------------- | ---------------------------------------------------- |
| setup                      | Rails app запускается и рендерит `tasks/show`                | `STEP-01..STEP-08`   | Нельзя проверить визуальный контракт страницы задачи |
| test                       | Каноничный verify через `bundle exec rspec` (system/request) | `STEP-05`, `STEP-06` | Нет доказательства сохранности контрактов            |
| access / network / secrets | Внешний AI для UI-проверки поля ввода не обязателен          | `STEP-05`, `STEP-08` | Флакки, не связанные с FT-011                        |


## Preconditions


| Precondition ID | Canonical ref              | Required state                                     | Used by steps                   | Blocks start |
| --------------- | -------------------------- | -------------------------------------------------- | ------------------------------- | ------------ |
| `PRE-01`        | `CON-01`, `CON-02`         | Без новых gem и без изменений вне `ai-setup`       | `STEP-01..STEP-08`              | yes          |
| `PRE-02`        | `ASM-02`, `OQ-01`, `OQ-02` | Зафиксирована трактовка UI-only без submit/persist | `STEP-02`, `STEP-03`, `STEP-07` | yes          |


## Workstreams


| Workstream | Implements                   | Result                                                      | Owner | Dependencies       |
| ---------- | ---------------------------- | ----------------------------------------------------------- | ----- | ------------------ |
| `WS-1`     | `REQ-01`, `REQ-02`, `REQ-03` | На `/task/:id` доступно editable многострочное поле ввода   | agent | `PRE-01`, `PRE-02` |
| `WS-2`     | `REQ-04`                     | Тесты и документация синхронизированы с новым UI-контрактом | agent | `WS-1`             |


## Approval Gates


| Approval Gate ID | Trigger                                             | Applies to | Why approval is required               | Approver / evidence           |
| ---------------- | --------------------------------------------------- | ---------- | -------------------------------------- | ----------------------------- |
| `AG-01`          | Часть проверки удобства ввода остается manual smoke | `STEP-08`  | Нужна фиксация manual-only UX evidence | human approval в issue/review |


## Порядок работ


| Step ID   | Actor | Implements         | Goal                                                             | Touchpoints                                                                | Artifact                                 | Verifies | Evidence IDs | Check command / procedure                                                                                      | Blocked by          | Needs approval | Escalate if                                                     |
| --------- | ----- | ------------------ | ---------------------------------------------------------------- | -------------------------------------------------------------------------- | ---------------------------------------- | -------- | ------------ | -------------------------------------------------------------------------------------------------------------- | ------------------- | -------------- | --------------------------------------------------------------- |
| `STEP-01` | agent | `REQ-01`, `REQ-03` | Зафиксировать текущий layout `tasks/show` и доступные UI hooks   | `tasks/show.html.erb`, `application.css`                                   | Discovery notes в PR/комментарии         | `CHK-01` | `EVID-01`    | code inspection                                                                                                | `PRE-01`            | none           | Поле ввода уже частично реализовано и конфликтует с новым scope |
| `STEP-02` | agent | `REQ-01`, `REQ-02` | Добавить в `tasks/show` многострочное поле ввода кода-решения    | `tasks/show.html.erb`                                                      | Обновлённый шаблон страницы задачи       | `CHK-01` | `EVID-01`    | system test + manual open page                                                                                 | `STEP-01`, `PRE-02` | none           | Появляется необходимость backend submit/persist вне FT-011      |
| `STEP-03` | agent | `REQ-02`, `REQ-03` | Добавить/адаптировать стили поля без деградации существующего UI | `application.css`                                                          | Читаемый input на desktop/mobile         | `CHK-01` | `EVID-01`    | targeted visual regression                                                                                     | `STEP-02`           | none           | Стили затрагивают несвязанные экраны                            |
| `STEP-04` | agent | `REQ-03`           | Проверить отсутствие изменений в controller/routes контракте     | `tasks_controller.rb`, `routes.rb`                                         | Подтвержденный UI-only scope             | `CHK-02` | `EVID-02`    | request regression (dry check)                                                                                 | `STEP-03`           | none           | Потребовались API changes                                       |
| `STEP-05` | agent | `REQ-04`           | Обновить и прогнать system coverage для нового поля              | `spec/system/generation_request_flow_spec.rb`                              | Зеленый system regression                | `CHK-01` | `EVID-01`    | `cd task_generator && bundle exec rspec spec/system/generation_request_flow_spec.rb`                           | `STEP-03`           | none           | Нельзя стабильно проверить наличие/editable поля                |
| `STEP-06` | agent | `REQ-03`, `REQ-04` | Прогнать request regression на сохранность reopen/API контрактов | `spec/requests/tasks_spec.rb`, `spec/requests/generation_requests_spec.rb` | Зеленый request regression               | `CHK-02` | `EVID-02`    | `cd task_generator && bundle exec rspec spec/requests/tasks_spec.rb spec/requests/generation_requests_spec.rb` | `STEP-05`           | none           | Изменились `E302/E303` или submit payload                       |
| `STEP-07` | agent | `REQ-04`           | Синхронизировать пользовательскую документацию                   | `task_generator/README.md`                                                 | Актуальное описание шага решения         | `CHK-02` | `EVID-02`    | doc review against tests                                                                                       | `STEP-06`           | none           | README расходится с фактическим поведением                      |
| `STEP-08` | agent | `REQ-01..REQ-04`   | Выполнить manual smoke и собрать итоговое evidence               | test logs + smoke notes                                                    | Полный пакет evidence `EVID-01..EVID-03` | `CHK-03` | `EVID-03`    | manual smoke: открыть `/task/:id`, ввести многострочный Ruby-код                                               | `STEP-07`           | `AG-01`        | UX поведения поля спорно без уточнения issue-owner              |


## Parallelizable Work

- `PAR-01` Подготовку `STEP-07` (черновик README) можно начать параллельно с `STEP-05`.
- `PAR-02` Review текущих request-контрактов (`STEP-04`) можно делать параллельно с подготовкой system-спеки (`STEP-05`).

## Checkpoints


| Checkpoint ID | Refs               | Condition                                              | Evidence IDs         |
| ------------- | ------------------ | ------------------------------------------------------ | -------------------- |
| `CP-01`       | `STEP-01..STEP-03` | Поле ввода добавлено и визуально стабильно             | `EVID-01`            |
| `CP-02`       | `STEP-04..STEP-06` | Reopen/API контракты не изменились                     | `EVID-01`, `EVID-02` |
| `CP-03`       | `STEP-07..STEP-08` | Документация и smoke подтверждают итоговый UI-контракт | `EVID-02`, `EVID-03` |


## Execution Risks


| Risk ID | Risk                                                    | Impact                                   | Mitigation                                    | Trigger                                         |
| ------- | ------------------------------------------------------- | ---------------------------------------- | --------------------------------------------- | ----------------------------------------------- |
| `ER-01` | Поле ввода есть в DOM, но недоступно для редактирования | Пользователь не может писать решение     | Проверять `editable` в system + manual smoke  | Отсутствует ввод/курсор в поле                  |
| `ER-02` | UI-изменение случайно ломает reopen-страницу            | Регрессия основного сценария `/task/:id` | Request regression `tasks_spec` обязателен    | Падение `E302/E303` тестов                      |
| `ER-03` | Фича расползётся в submit/persist logic вне scope       | Непредсказуемый рост объема и рисков     | Жестко держать UI-only границы `NS-01..NS-03` | Появился запрос на новые endpoint/model changes |


## Stop Conditions / Fallback


| Stop ID   | Related refs      | Trigger                                                             | Immediate action                                                                  | Safe fallback state                                           |
| --------- | ----------------- | ------------------------------------------------------------------- | --------------------------------------------------------------------------------- | ------------------------------------------------------------- |
| `STOP-01` | `OQ-01`, `NS-01`  | Уточнение owner: нужен немедленный submit/check кода в этой же фиче | Остановить реализацию и зафиксировать новый scope через отдельный feature package | Вернуться к UI-only изменениям последнего зеленого checkpoint |
| `STOP-02` | `CON-01`, `NS-03` | Для ввода требуется внешняя зависимость/code editor пакет           | Эскалировать и не добавлять dependency автономно                                  | Оставить базовый `textarea` без новых пакетов                 |


## Готово для приемки

План считается выполненным, когда:

- пройдены `CP-01..CP-03`;
- собраны `EVID-01..EVID-03`;
- подтверждены `EC-01..EC-03` из `feature.md`.

