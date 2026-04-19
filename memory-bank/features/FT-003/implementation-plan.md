---
title: "FT-003: Implementation Plan"
doc_kind: feature
doc_function: derived
purpose: "Execution-план реализации FT-003: создание `Task`, контракт reopen по `GET /task/:id` и ошибки `E301-E303`."
derived_from:
  - feature.md
status: active
audience: humans_and_agents
must_not_define:
  - ft_003_scope
  - ft_003_architecture
  - ft_003_acceptance_criteria
  - ft_003_blocker_state
---

# План имплементации

## Цель текущего плана

Внедрить хранение и повторное открытие последней сгенерированной задачи так, чтобы после закрытия вкладки пользователь мог снова открыть ту же задачу по URL без повторной генерации.

## Current State / Reference Points

| Path / module | Current role | Why relevant | Reuse / mirror |
| --- | --- | --- | --- |
| `task_generator/config/routes.rb` | Маршруты generation flow | Нужны `GET /task/:id` и обновление submit контракта | Сохранить явную приоритизацию роутов |
| `task_generator/app/controllers/generation_requests_controller.rb` | Endpoint submit | Нужно вернуть `task_id/task_path` на `SUCCESS` | Mirror существующий JSON response pattern |
| `task_generator/app/services/generation_requests/submit_service.rb` | Оркестрация submit | Нужно добавить создание `Task` и `E301` | Сохранить passthrough для `E201-E209` |
| `task_generator/app/services/generation/build_description_service.rb` | Генерация описания | Нужно гарантировать ошибки `E206-E209` до создания `Task` | Не менять бизнес-логику вне контракта |
| `task_generator/app/javascript/controllers/generation_request_form_controller.js` | Клиентский flow | Нужен redirect на `task_path` | Убрать legacy переход на `generation_flow` |
| `task_generator/spec/` | Автотесты | Нужны тесты на создание/отсутствие `Task` и reopen | Распределить по services/requests/system |

## Test Strategy

| Test surface | Canonical refs | Existing coverage | Planned automated coverage | Required local suites / commands | Required CI suites / jobs | Manual-only gap / justification | Manual-only approval ref |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `Task` model and persistence | `REQ-01`, `SC-01`, `CHK-01` | Нет | Model/factory tests на `description` и length<=150 | `cd task_generator && bundle exec rspec spec/models/task_spec.rb` | Rails RSpec | none | none |
| `SubmitService` + generation pipeline | `REQ-01`, `REQ-03`, `SC-02`, `NEG-01`, `CHK-01` | Частично | Service tests на `E301`, passthrough `E201-E209`, no `Task` growth | `cd task_generator && bundle exec rspec spec/services/generation_requests/submit_service_spec.rb spec/services/generation/build_description_service_spec.rb` | Rails RSpec | none | none |
| `POST /generation_requests` contract | `REQ-02`, `REQ-03`, `SC-01`, `SC-02`, `CHK-02` | Частично | Request tests `SUCCESS task_id/task_path`, `ERROR error_code` | `cd task_generator && bundle exec rspec spec/requests/generation_requests_spec.rb` | Rails RSpec | none | none |
| `GET /task/:id` reopen behavior | `REQ-04`, `SC-03`, `SC-04`, `NEG-02`, `CHK-03` | Нет | Request/system tests на `200`, `E302`, `E303`, reopen без генерации | `cd task_generator && bundle exec rspec spec/requests/tasks_spec.rb spec/system/generation_request_flow_spec.rb` | Rails RSpec/System | Возможен manual-only stress сценарий окна 200 reopen | `AG-01` |

## Open Questions / Ambiguities

| Open Question ID | Question | Why unresolved | Blocks | Default action / escalation owner |
| --- | --- | --- | --- | --- |
| `OQ-01` | Нужно ли сохранять связь `Task` с `GenerationRequest` отдельным FK в рамках FT-003 | В исходной постановке не требуется явный FK | `STEP-01`, `STEP-04` | По умолчанию хранить только `description`; эскалировать, если появится требование аудит-трейла |

## Environment Contract

| Area | Contract | Used by | Failure symptom |
| --- | --- | --- | --- |
| setup | Миграции выполняются в локальной БД, schema актуальна | `STEP-01`, `STEP-09` | Невозможно создать/прочитать `Task` |
| test | Эталон verify: `bundle exec rspec` по services/requests/system | `STEP-07`, `STEP-09` | Нет доказательства AC-01..AC-08 |
| access / network / secrets | Внешний доступ не требуется, генерация в тестах стабируется | `STEP-02..STEP-09` | Флакки по сети вместо deterministic ошибок |

## Preconditions

| Precondition ID | Canonical ref | Required state | Used by steps | Blocks start |
| --- | --- | --- | --- | --- |
| `PRE-01` | `CON-01`, `CON-02`, `CON-03` | Нет новых gem, работа в пределах 3 модулей | `STEP-01..STEP-09` | yes |
| `PRE-02` | `ASM-01` | `BuildDescriptionService` уже выдаёт стабильный `SUCCESS/ERROR` контракт | `STEP-02`, `STEP-04`, `STEP-05` | yes |

## Workstreams

| Workstream | Implements | Result | Owner | Dependencies |
| --- | --- | --- | --- | --- |
| `WS-1` | `REQ-01` | Модель `Task` и хранение описания | agent | `PRE-01` |
| `WS-2` | `REQ-03` | Orchestration submit + ошибки `E301` | agent | `WS-1`, `PRE-02` |
| `WS-3` | `REQ-02`, `REQ-04` | HTTP/UI reopen контракт `POST -> GET /task/:id` | agent | `WS-2` |
| `WS-4` | `REQ-01..REQ-04` | Тесты и документация | agent | `WS-1`, `WS-2`, `WS-3` |

## Approval Gates

| Approval Gate ID | Trigger | Applies to | Why approval is required | Approver / evidence |
| --- | --- | --- | --- | --- |
| `AG-01` | AC-08 проверяется только ручным стресс-сценарием reopen | `STEP-07`, `STEP-09` | Manual-only gap должен быть явно принят | human approval в review/issue |
| `AG-02` | Требуется менять legacy `generation_flow` вне scope FT-003 | `STEP-03`, `STEP-06` | Нарушает `CON-03` и модульные границы | human decision в tracker |

## Порядок работ

| Step ID | Actor | Implements | Goal | Touchpoints | Artifact | Verifies | Evidence IDs | Check command / procedure | Blocked by | Needs approval | Escalate if |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `STEP-01` | agent | `REQ-01` | Добавить слой хранения `Task` | `db/migrate/*_create_tasks.rb`, `app/models/task.rb`, `spec/models/task_spec.rb`, `spec/factories/tasks.rb`, `db/schema.rb` | Таблица + модель `Task` | `CHK-01` | `EVID-01` | `cd task_generator && bin/rails db:migrate && bundle exec rspec spec/models/task_spec.rb` | `PRE-01` | none | Миграция конфликтует с существующей схемой |
| `STEP-02` | agent | `REQ-03` | Зафиксировать ошибки `E206-E209` до создания `Task` | `app/services/generation/build_description_service.rb`, `spec/services/generation/build_description_service_spec.rb` | Стабильный `ERROR` до persistence | `CHK-01` | `EVID-01` | `cd task_generator && bundle exec rspec spec/services/generation/build_description_service_spec.rb` | `PRE-02` | none | Контракт `E201-E209` меняется |
| `STEP-03` | agent | `REQ-04` | Реализовать `GET /task/:id` + `E302/E303` | `config/routes.rb`, `app/controllers/tasks_controller.rb`, `app/views/tasks/show.html.erb`, `config/locales/*.yml`, `spec/requests/tasks_spec.rb` | Endpoint reopen без генерации | `CHK-03` | `EVID-03` | `cd task_generator && bundle exec rspec spec/requests/tasks_spec.rb` | `STEP-01` | `AG-02` (если надо менять legacy модуль) | Требуется вмешательство в `generation_flow` вне scope |
| `STEP-04` | agent | `REQ-01`, `REQ-03` | Расширить `SubmitService` созданием `Task` | `app/services/generation_requests/submit_service.rb`, `spec/services/generation_requests/submit_service_spec.rb` | `SUCCESS` создаёт `Task`, `E301` на fail save | `CHK-01`, `CHK-02` | `EVID-01`, `EVID-02` | `cd task_generator && bundle exec rspec spec/services/generation_requests/submit_service_spec.rb` | `STEP-01`, `STEP-02` | none | Нельзя сохранить passthrough для `E201-E209` |
| `STEP-05` | agent | `REQ-02`, `REQ-03` | Зафиксировать `POST /generation_requests` JSON-контракт | `app/controllers/generation_requests_controller.rb`, `spec/requests/generation_requests_spec.rb` | `SUCCESS: task_id/task_path`, `ERROR: error_code` | `CHK-02` | `EVID-02` | `cd task_generator && bundle exec rspec spec/requests/generation_requests_spec.rb` | `STEP-04` | none | Контроллер не может различить persisted/non-persisted id |
| `STEP-06` | agent | `REQ-02`, `REQ-04` | Обновить фронтенд flow на redirect `task_path` | `app/javascript/controllers/generation_request_form_controller.js`, `app/views/generation_requests/new.html.erb`, `config/locales/*.yml` | Немедленный переход на `/task/:id`, retry для `E301` | `CHK-02`, `CHK-03` | `EVID-02`, `EVID-03` | Request/system smoke | `STEP-05`, `STEP-03` | `AG-02` (если требует legacy changes) | Нужен переход через устаревший `generation_flow` |
| `STEP-07` | agent | `REQ-01..REQ-04` | Закрыть acceptance тестами | `spec/services/generation_requests/submit_service_spec.rb`, `spec/requests/generation_requests_spec.rb`, `spec/requests/tasks_spec.rb`, `spec/system/generation_request_flow_spec.rb` | Проверяемые AC-01..AC-08 | `CHK-01`, `CHK-02`, `CHK-03` | `EVID-01`, `EVID-02`, `EVID-03` | `cd task_generator && bundle exec rspec ...` | `STEP-06` | `AG-01` (если AC-08 manual-only) | Не удаётся автоматизировать критичный критерий |
| `STEP-08` | agent | `REQ-01..REQ-04` | Обновить README публичного контракта | `task_generator/README.md` | Документация `POST -> GET /task/:id`, `E301-E303` | `CHK-02`, `CHK-03` | `EVID-02`, `EVID-03` | Doc review against request specs | `STEP-07` | none | Документация расходится с тестами |
| `STEP-09` | agent | `REQ-01..REQ-04` | Прогнать целостную регрессию | без изменения кода | Подтверждена совместимость маршрутов/контрактов | `CHK-01`, `CHK-02`, `CHK-03` | `EVID-01`, `EVID-02`, `EVID-03` | `cd task_generator && bundle exec rspec` | `STEP-08` | `AG-01` (если manual gap зафиксирован) | Падает legacy coverage после изменений |

## Parallelizable Work

- `PAR-01` `STEP-02` (pipeline errors) можно вести параллельно с подготовкой `STEP-03` (tasks endpoint skeleton) после `STEP-01`.
- `PAR-02` Черновик `STEP-08` (README) можно вести параллельно `STEP-07`, финализировать после зелёных тестов.

## Checkpoints

| Checkpoint ID | Refs | Condition | Evidence IDs |
| --- | --- | --- | --- |
| `CP-01` | `STEP-01`, `STEP-02`, `CHK-01` | `Task` storage и error pipeline стабильны | `EVID-01` |
| `CP-02` | `STEP-03..STEP-06`, `CHK-02`, `CHK-03` | Reopen маршрут и frontend redirect работают | `EVID-02`, `EVID-03` |
| `CP-03` | `STEP-07..STEP-09` | Acceptance/regression зелёные, docs синхронизированы | `EVID-01`, `EVID-02`, `EVID-03` |

## Execution Risks

| Risk ID | Risk | Impact | Mitigation | Trigger |
| --- | --- | --- | --- | --- |
| `ER-01` | Нарушение backward compatibility `E201-E209` | Регрессия FT-002 и submit flow | Жёсткий passthrough контракт в service/request tests | Изменился код ошибки на старых сценариях |
| `ER-02` | Некорректный redirect после `SUCCESS` | Пользователь не попадает на reopenable URL | Проверять `task_path` в request+system тестах | UI остаётся на форме при `SUCCESS` |
| `ER-03` | Неполная обработка `E302/E303` | Непредсказуемые ошибки при reopen | Локализованный и тестируемый error contract в `TasksController` | 500/HTML fallback вместо ожидаемого кода |

## Stop Conditions / Fallback

| Stop ID | Related refs | Trigger | Immediate action | Safe fallback state |
| --- | --- | --- | --- | --- |
| `STOP-01` | `CON-01` | Понадобился новый gem | Остановить реализацию и запросить решение | Вернуться к текущему контракту без новых зависимостей |
| `STOP-02` | `CON-03`, `AG-02` | Требуется менять модуль вне границ FT-003 | Зафиксировать blocker и эскалировать | Заморозить изменения на последнем checkpoint |

## Готово для приемки

План считается выполненным, когда:
- пройдены `CP-01..CP-03`;
- собраны `EVID-01..EVID-03`;
- подтверждены `EC-01..EC-03` и AC-01..AC-08 из `feature.md`.
