---

## title: "FT-012: Implementation Plan"
doc_kind: feature
doc_function: derived
purpose: "Execution-план реализации FT-012: сохранить пользовательский `solution_code` для задачи и показывать его при reopen `/task/:id`."
derived_from:
  - feature.md
status: active
audience: humans_and_agents
must_not_define:
  - ft_012_scope
  - ft_012_architecture
  - ft_012_acceptance_criteria
  - ft_012_blocker_state

# План имплементации

## Цель текущего плана

Добавить persistence для пользовательского `solution_code` на странице задачи и сохранить обратную совместимость generation/reopen контрактов.

## Current State / Reference Points


| Path / module                                                | Current role                                         | Why relevant                                  | Reuse / mirror                                 |
| ------------------------------------------------------------ | ---------------------------------------------------- | --------------------------------------------- | ---------------------------------------------- |
| `task_generator/db/schema.rb`                                | В таблице `tasks` есть только `description`          | Нужна миграция для поля `solution_code`       | Сохраняем текущие ограничения `description`    |
| `task_generator/app/models/task.rb`                          | Валидация только `description`                       | Нужен model-контракт для нового атрибута      | Повторить текущий подход минимальных валидаций |
| `task_generator/config/routes.rb`                            | Есть только `GET /task/:id`                          | Нужно добавить action сохранения решения      | Сохранить существующий путь show               |
| `task_generator/app/controllers/tasks_controller.rb`         | Реализован только `show` + `E302/E303`               | Добавить update-сценарий без регрессии ошибок | Использовать текущий `render_error`            |
| `task_generator/app/views/tasks/show.html.erb`               | Есть textarea `solution_code`, но без submit/persist | Точка для формы сохранения и prefill          | Сохранить текущий layout страницы задачи       |
| `task_generator/spec/requests/tasks_spec.rb`                 | Покрывает контракт `GET /task/:id` и ошибки          | Нужны проверки сохранения/очистки решения     | Расширить существующий request coverage        |
| `task_generator/spec/system/generation_request_flow_spec.rb` | Сквозной flow генерации и перехода на задачу         | Нужно проверить persistence после reopen      | Использовать как acceptance suite              |
| `task_generator/README.md`                                   | Явно зафиксировано "UI-only, без сохранения в БД"    | Контракт документации изменится               | Синхронизировать после зеленых тестов          |


## Test Strategy


| Test surface                        | Canonical refs                                  | Existing coverage                  | Planned automated coverage                                                           | Required local suites / commands                                                              | Required CI suites / jobs | Manual-only gap / justification               | Manual-only approval ref |
| ----------------------------------- | ----------------------------------------------- | ---------------------------------- | ------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------- | ------------------------- | --------------------------------------------- | ------------------------ |
| Data/model contract `solution_code` | `REQ-01`, `REQ-04`, `SC-01`, `SC-03`, `CHK-01`  | Нет `solution_code` в модели/схеме | Добавить/обновить model + request проверки на save/clear                             | `cd task_generator && bundle exec rspec spec/models/task_spec.rb spec/requests/tasks_spec.rb` | models+requests / rspec   | none                                          | none                     |
| UI flow save/reopen                 | `REQ-02`, `REQ-03`, `SC-02`, `NEG-02`, `CHK-02` | Есть flow без persistence          | Добавить system assertions: save -> reload -> reopen показывает сохраненное значение | `cd task_generator && bundle exec rspec spec/system/generation_request_flow_spec.rb`          | system / rspec            | Короткий manual smoke для UX текста/сообщений | `AG-01`                  |
| Docs sync                           | `REQ-05`, `SC-04`, `CHK-01`                     | README описывает UI-only поле      | Обновить `task_generator/README.md` под DB persistence                               | doc review + related rspec suites                                                             | docs-check / review       | none                                          | none                     |


## Open Questions / Ambiguities


| Open Question ID | Question                                                   | Why unresolved                           | Blocks                          | Default action / escalation owner                                                                          |
| ---------------- | ---------------------------------------------------------- | ---------------------------------------- | ------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| `OQ-01`          | Нужен autosave или достаточно явного сохранения action-ом? | Issue #12 содержит только короткий title | `STEP-04`, `STEP-05`, `STEP-07` | По умолчанию реализовать явное сохранение из `ASM-01`; autosave вынести в отдельную фичу при необходимости |
| `OQ-02`          | Нужен ли продуктовый лимит длины `solution_code` в FT-012? | В issue нет ограничений размера          | `STEP-03`, `STEP-06`            | По умолчанию не вводить новый UX-лимит; эскалировать только при явном требовании                           |


## Environment Contract


| Area                       | Contract                                                                        | Used by            | Failure symptom                                |
| -------------------------- | ------------------------------------------------------------------------------- | ------------------ | ---------------------------------------------- |
| setup                      | Rails app и БД готовы к миграциям                                               | `STEP-01..STEP-09` | Нельзя применить схему и проверить persistence |
| test                       | Каноничный verify через `bundle exec rspec` (model/request/system)              | `STEP-06..STEP-08` | Нет evidence выполнения `EC-*`                 |
| access / network / secrets | Для FT-012 внешний AI не обязателен, тесты должны быть локально детерминированы | `STEP-06..STEP-09` | Флакки не по change surface                    |


## Preconditions


| Precondition ID | Canonical ref      | Required state                                          | Used by steps                   | Blocks start |
| --------------- | ------------------ | ------------------------------------------------------- | ------------------------------- | ------------ |
| `PRE-01`        | `CON-01`, `CON-02` | Без новых gem и без изменений вне `ai-setup`            | `STEP-01..STEP-09`              | yes          |
| `PRE-02`        | `ASM-01`, `OQ-01`  | Зафиксирована трактовка: явное сохранение, без autosave | `STEP-04`, `STEP-05`, `STEP-07` | yes          |
| `PRE-03`        | `REQ-01`           | Разрешено обновление схемы БД миграцией                 | `STEP-02`, `STEP-03`            | yes          |


## Workstreams


| Workstream | Implements         | Result                                                        | Owner | Dependencies       |
| ---------- | ------------------ | ------------------------------------------------------------- | ----- | ------------------ |
| `WS-1`     | `REQ-01`, `REQ-04` | Слой данных хранит и очищает `solution_code`                  | agent | `PRE-01`, `PRE-03` |
| `WS-2`     | `REQ-02`, `REQ-03` | HTTP/UI контракт сохранения и prefill работает на `/task/:id` | agent | `WS-1`, `PRE-02`   |
| `WS-3`     | `REQ-05`           | Тесты и документация синхронизированы                         | agent | `WS-2`             |


## Approval Gates


| Approval Gate ID | Trigger                                             | Applies to                      | Why approval is required                        | Approver / evidence           |
| ---------------- | --------------------------------------------------- | ------------------------------- | ----------------------------------------------- | ----------------------------- |
| `AG-01`          | Требуется UX-решение между autosave и explicit save | `STEP-04`, `STEP-07`, `STEP-09` | Влияет на продуктовый контракт и границы FT-012 | human approval в issue/review |


## Порядок работ


| Step ID   | Actor | Implements         | Goal                                                                     | Touchpoints                                                            | Artifact                                 | Verifies | Evidence IDs | Check command / procedure                                                                     | Blocked by          | Needs approval                 | Escalate if                                       |
| --------- | ----- | ------------------ | ------------------------------------------------------------------------ | ---------------------------------------------------------------------- | ---------------------------------------- | -------- | ------------ | --------------------------------------------------------------------------------------------- | ------------------- | ------------------------------ | ------------------------------------------------- |
| `STEP-01` | agent | `REQ-01..REQ-04`   | Зафиксировать текущий UI-only контракт `solution_code` и точки изменений | `routes.rb`, `tasks_controller.rb`, `tasks/show.html.erb`, `schema.rb` | Discovery notes в PR/комментарии         | `CHK-01` | `EVID-01`    | code inspection                                                                               | `PRE-01`            | none                           | Найдена скрытая зависимость, меняющая scope       |
| `STEP-02` | agent | `REQ-01`           | Добавить миграцию и поле `tasks.solution_code`                           | `db/migrate/*`, `db/schema.rb`                                         | Обновленная схема БД                     | `CHK-01` | `EVID-01`    | migrate + schema diff review                                                                  | `STEP-01`, `PRE-03` | none                           | Миграция требует downtime/сложного backfill       |
| `STEP-03` | agent | `REQ-01`, `REQ-04` | Обновить model-контракт для чтения/записи `solution_code`                | `app/models/task.rb`                                                   | Стабильный Task contract                 | `CHK-01` | `EVID-01`    | model specs                                                                                   | `STEP-02`           | none                           | Появляется необходимость нового error-code лимита |
| `STEP-04` | agent | `REQ-02`           | Добавить маршрут и controller action сохранения решения                  | `config/routes.rb`, `app/controllers/tasks_controller.rb`              | HTTP контракт save action                | `CHK-01` | `EVID-01`    | request specs                                                                                 | `STEP-03`, `PRE-02` | `AG-01` при споре про autosave | Нужен другой UX-контракт (autosave/API)           |
| `STEP-05` | agent | `REQ-03`, `REQ-04` | Превратить textarea в persist-flow: prefill + submit + clear             | `app/views/tasks/show.html.erb`, `config/locales/ru.yml`               | Рабочий UI сохранения на `/task/:id`     | `CHK-02` | `EVID-02`    | system test + manual open page                                                                | `STEP-04`           | none                           | View требует JS-слой вне оговоренного scope       |
| `STEP-06` | agent | `REQ-04`, `REQ-05` | Добавить/обновить model+request tests под новый контракт                 | `spec/models/task_spec.rb`, `spec/requests/tasks_spec.rb`              | Зеленый model/request regression         | `CHK-01` | `EVID-01`    | `cd task_generator && bundle exec rspec spec/models/task_spec.rb spec/requests/tasks_spec.rb` | `STEP-05`           | none                           | Падает старый контракт `E302/E303`                |
| `STEP-07` | agent | `REQ-03`, `REQ-05` | Обновить system flow на save/reopen проверку                             | `spec/system/generation_request_flow_spec.rb`                          | Зеленый system regression                | `CHK-02` | `EVID-02`    | `cd task_generator && bundle exec rspec spec/system/generation_request_flow_spec.rb`          | `STEP-06`           | `AG-01` при конфликте UX       | Тест нестабилен без смены продукта/UX             |
| `STEP-08` | agent | `REQ-05`           | Синхронизировать docs (`task_generator/README.md`)                       | `task_generator/README.md`                                             | Актуальный пользовательский контракт     | `CHK-01` | `EVID-01`    | doc review against tests                                                                      | `STEP-07`           | none                           | README не совпадает с реальным flow               |
| `STEP-09` | agent | `REQ-01..REQ-05`   | Выполнить manual smoke и собрать evidence                                | test logs + smoke notes                                                | Полный пакет evidence `EVID-01..EVID-03` | `CHK-03` | `EVID-03`    | открыть `/task/:id`, сохранить код, refresh/reopen, очистить и сохранить                      | `STEP-08`           | `AG-01`                        | Владелец issue ожидает другой UX сохранения       |


## Parallelizable Work

- `PAR-01` Черновик `STEP-08` (README) можно подготовить параллельно с `STEP-06`, финализировать после `STEP-07`.
- `PAR-02` Часть request assertions (`STEP-06`) можно писать параллельно с финальной разметкой `STEP-05`, если контракт route уже зафиксирован.

## Checkpoints


| Checkpoint ID | Refs               | Condition                                                      | Evidence IDs         |
| ------------- | ------------------ | -------------------------------------------------------------- | -------------------- |
| `CP-01`       | `STEP-01..STEP-03` | Data-layer готов: `solution_code` добавлен и стабилен в модели | `EVID-01`            |
| `CP-02`       | `STEP-04..STEP-07` | HTTP/UI save/reopen flow проходит automated coverage           | `EVID-01`, `EVID-02` |
| `CP-03`       | `STEP-08..STEP-09` | Docs и smoke подтверждают итоговый контракт FT-012             | `EVID-01`, `EVID-03` |


## Execution Risks


| Risk ID | Risk                                                              | Impact                                | Mitigation                                                   | Trigger                                      |
| ------- | ----------------------------------------------------------------- | ------------------------------------- | ------------------------------------------------------------ | -------------------------------------------- |
| `ER-01` | Сохранение не работает из-за неполного strong params/route wiring | Пользователь теряет введенное решение | Проверять request-контракт до UI smoke                       | PATCH/submit не меняет значение после reload |
| `ER-02` | Рендер сохраненного кода нарушит безопасность вывода              | XSS-риск на странице задачи           | Оставить экранирование Rails по умолчанию и покрыть `NEG-02` | В браузере выполняется HTML/JS из textarea   |
| `ER-03` | Изменение `tasks#show` затронет reopen ошибки                     | Регрессия `E302/E303`                 | Обязательный regression в `tasks_spec`                       | Падают текущие request проверки ошибок       |


## Stop Conditions / Fallback


| Stop ID   | Related refs      | Trigger                                                                             | Immediate action                                                | Safe fallback state                                        |
| --------- | ----------------- | ----------------------------------------------------------------------------------- | --------------------------------------------------------------- | ---------------------------------------------------------- |
| `STOP-01` | `OQ-01`, `ASM-01` | Владелец issue требует autosave вместо explicit save в рамках той же задачи         | Остановить реализацию и обновить canonical scope в `feature.md` | Вернуться к последнему зеленому checkpoint до UI-контракта |
| `STOP-02` | `CON-01`, `NS-04` | Для реализации требуется новая зависимость или изменение generation API/error codes | Эскалировать blocker и не продолжать автономно                  | Сохранить только согласованные schema/model изменения      |


## Готово для приемки

План считается выполненным, когда:

- пройдены `CP-01..CP-03`;
- собраны `EVID-01..EVID-03`;
- подтверждены `EC-01..EC-03` из `feature.md`.

