---
title: "FT-001: Implementation Plan"
doc_kind: feature
doc_function: derived
purpose: "Execution-план реализации FT-001 с шагами внедрения формы `skill/topic`, валидации и перехода к следующему шагу."
derived_from:
  - feature.md
status: active
audience: humans_and_agents
must_not_define:
  - ft_001_scope
  - ft_001_architecture
  - ft_001_acceptance_criteria
  - ft_001_blocker_state
---

# План имплементации

## Цель текущего плана

Довести FT-001 до состояния, в котором пользователь всегда проходит обязательный шаг ввода `skill/topic` перед генерацией задачи, а система предсказуемо обрабатывает ошибки `E001-E007`.

## Current State / Reference Points

| Path / module | Current role | Why relevant | Reuse / mirror |
| --- | --- | --- | --- |
| `task_generator/config/routes.rb` | Маршрутизация формы и следующего шага | Нужно добавить GET/POST точки входа | Сохранять существующий стиль route helpers |
| `task_generator/app/models/` | Доменные модели Rails | Нужна новая модель `GenerationRequest` | Повторить паттерн Rails validations + callbacks |
| `task_generator/app/services/` | Слой оркестрации бизнес-процессов | Нужен `GenerationRequests::SubmitService` | Следовать service object паттерну проекта |
| `task_generator/app/views/generation_requests/new.html.erb` | UI формы | Нужно показать ошибки и state machine-поведение | Использовать существующие form helpers |
| `task_generator/app/javascript/controllers/` | Клиентская логика форм | Нужен контроллер для `EMPTY/ERROR/READY/LOADING` | Повторить Stimulus-паттерн проекта |
| `task_generator/spec/` | Автотесты | Нужно покрыть `E001-E007` и переходы | Использовать RSpec + FactoryBot conventions |

## Test Strategy

| Test surface | Canonical refs | Existing coverage | Planned automated coverage | Required local suites / commands | Required CI suites / jobs | Manual-only gap / justification | Manual-only approval ref |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `GenerationRequest` model | `REQ-02`, `SC-02`, `NEG-01`, `NEG-02`, `CHK-01` | Нет | Unit tests на нормализацию и `E001-E006` | `cd task_generator && bundle exec rspec spec/models/generation_request_spec.rb` | Rails RSpec | none | none |
| `SubmitService` + request contract | `REQ-03`, `REQ-04`, `SC-01`, `SC-03`, `CHK-01` | Нет | Service/request tests на success + `E007` | `cd task_generator && bundle exec rspec spec/services/generation_requests/submit_service_spec.rb spec/requests/generation_requests_spec.rb` | Rails RSpec | none | none |
| UI state machine | `REQ-03`, `SC-03`, `CHK-02` | Нет | System smoke на состояния формы | `cd task_generator && bundle exec rspec spec/system/generation_request_flow_spec.rb` | Rails System Tests | Возможен ручной smoke для timeout-ветки, если сложно детерминировать | `AG-01` |

## Open Questions / Ambiguities

| Open Question ID | Question | Why unresolved | Blocks | Default action / escalation owner |
| --- | --- | --- | --- | --- |
| `OQ-01` | Нужен ли отдельный retry endpoint для `E007` или повторный POST в тот же endpoint | Зависит от текущего контроллера и UX-решения | `STEP-03`, `STEP-06` | По умолчанию использовать тот же `POST /generation_requests`; при конфликте с UI ожиданиями эскалировать человеку |

## Environment Contract

| Area | Contract | Used by | Failure symptom |
| --- | --- | --- | --- |
| setup | Ruby/Rails окружение проекта поднято, БД доступна | `STEP-01`, `STEP-02` | Миграции/модельные тесты падают до бизнес-проверок |
| test | Эталонный verify: `bundle exec rspec` по целевым suite | `STEP-07`, `CHK-01`, `CHK-02` | Нельзя доказать выполнение `EC-*` |
| access / network / secrets | Внешняя сеть не нужна, фича локальная | `STEP-01..STEP-08` | Любая зависимость от внешнего API указывает на ошибку scope |

## Preconditions

| Precondition ID | Canonical ref | Required state | Used by steps | Blocks start |
| --- | --- | --- | --- | --- |
| `PRE-01` | `CON-01`, `CON-03` | Не добавляются новые gem и нет изменений вне `ai-setup` | `STEP-01..STEP-08` | yes |
| `PRE-02` | `ASM-01` | Следующий шаг генерации доступен для передачи `skill/topic` | `STEP-05`, `STEP-06` | yes |

## Workstreams

| Workstream | Implements | Result | Owner | Dependencies |
| --- | --- | --- | --- | --- |
| `WS-1` | `REQ-01`, `REQ-02` | Модель + миграция + серверная валидация | agent | `PRE-01` |
| `WS-2` | `REQ-03`, `REQ-04` | Контроллер/роутинг/UI + переход на следующий шаг | agent | `WS-1` |
| `WS-3` | `REQ-01..REQ-04` | Покрытие тестами и документация | agent | `WS-1`, `WS-2` |

## Approval Gates

| Approval Gate ID | Trigger | Applies to | Why approval is required | Approver / evidence |
| --- | --- | --- | --- | --- |
| `AG-01` | Для выполнения шага нужна manual-only проверка вместо автоматизации | `STEP-06`, `STEP-07` | Нужно явное подтверждение приемлемости временного manual gap | human approval в review/issue |
| `AG-02` | Появилась необходимость добавить gem или выйти за пределы проекта | `STEP-01..STEP-08` | Нарушает `CON-01`/`CON-03` и требует отдельного решения | human decision в issue/comment |

## Порядок работ

| Step ID | Actor | Implements | Goal | Touchpoints | Artifact | Verifies | Evidence IDs | Check command / procedure | Blocked by | Needs approval | Escalate if |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `STEP-01` | agent | `REQ-01`, `REQ-02` | Создать слой данных `generation_requests` | `db/migrate`, `app/models/generation_request.rb`, `db/schema.rb` | Таблица + модель с нормализацией и `E001-E006` | `CHK-01` | `EVID-01` | `cd task_generator && bin/rails db:migrate` | `PRE-01` | none | Миграция конфликтует с текущей схемой |
| `STEP-02` | agent | `REQ-03` | Реализовать `GenerationRequests::SubmitService` | `app/services/generation_requests/submit_service.rb` | Оркестрация success/validation/server error | `CHK-01` | `EVID-01` | `bin/rails runner` smoke success/error | `STEP-01` | none | Ошибки не маппятся на `E007` |
| `STEP-03` | agent | `REQ-01`, `REQ-03` | Добавить HTTP-слой формы | `config/routes.rb`, `app/controllers/generation_requests_controller.rb` | Рабочие GET/POST маршруты | `CHK-01` | `EVID-01` | `cd task_generator && bin/rails routes | rg generation_requests` | `STEP-02`, `OQ-01` | none | Контракт нельзя соблюсти в рамках текущего controller слоя |
| `STEP-04` | agent | `REQ-01`, `REQ-03` | Сделать форму и локализацию ошибок | `app/views/generation_requests/new.html.erb`, `config/locales/ru.yml`, `config/application.rb` | UI отображает `E001-E007` | `CHK-02` | `EVID-02` | Ручной form smoke | `STEP-03` | none | Локализация ломает существующие экраны |
| `STEP-05` | agent | `REQ-04` | Добавить шаг-приёмник после успеха | `app/controllers/generation_flow_controller.rb`, `app/views/generation_flow/show.html.erb`, `config/routes.rb` | Редирект и отображение `skill/topic` | `CHK-02` | `EVID-02` | Валидный submit -> проверка UI | `STEP-03`, `PRE-02` | none | Переход невозможен без изменения out-of-scope логики |
| `STEP-06` | agent | `REQ-03` | Добавить клиентскую state machine | `app/javascript/controllers/generation_request_form_controller.js`, `new.html.erb`, `application.css` | `EMPTY/ERROR/READY/LOADING` + блокировка двойного submit | `CHK-02` | `EVID-02` | System/manual UI smoke | `STEP-04`, `STEP-05` | `AG-01` (если manual-only) | Нужен browser-only сценарий без автоматизации |
| `STEP-07` | agent | `REQ-01..REQ-04` | Добавить покрытие RSpec/FactoryBot | `spec/models`, `spec/services`, `spec/requests`, `spec/system`, `spec/factories` | Автотесты по `E001-E007` и переходам | `CHK-01`, `CHK-02` | `EVID-01`, `EVID-02` | `cd task_generator && bundle exec rspec` | `STEP-06` | `AG-01` (если остаётся manual gap) | Не удаётся покрыть критичные ветки автоматизированно |
| `STEP-08` | agent | `REQ-01..REQ-04` | Обновить пользовательскую документацию | `task_generator/README.md` | Описание шага, кодов ошибок и команд verify | `CHK-01` | `EVID-01` | Док-ревью + smoke воспроизведение | `STEP-07` | none | README расходится с фактическим контрактом |

## Parallelizable Work

- `PAR-01` `STEP-04` (локализация/UI) и часть `STEP-05` (view приёмника) можно вести параллельно после готовности `STEP-03`.
- `PAR-02` `STEP-08` можно начать черновиком после `STEP-05`, но финализировать только после `STEP-07`.

## Checkpoints

| Checkpoint ID | Refs | Condition | Evidence IDs |
| --- | --- | --- | --- |
| `CP-01` | `STEP-01`, `STEP-02`, `CHK-01` | Серверный контракт валидации/submit работает | `EVID-01` |
| `CP-02` | `STEP-03..STEP-06`, `CHK-02` | UI/state machine и переход на следующий шаг работают | `EVID-02` |
| `CP-03` | `STEP-07`, `STEP-08`, `CHK-01`, `CHK-02` | Тесты зелёные, документация синхронизирована | `EVID-01`, `EVID-02` |

## Execution Risks

| Risk ID | Risk | Impact | Mitigation | Trigger |
| --- | --- | --- | --- | --- |
| `ER-01` | Расхождение клиентской и серверной валидации | Ложные разрешения/блокировки submit | Дублировать проверки и покрыть request+system тестами | Несовпадение поведения UI и API |
| `ER-02` | Нестабильная обработка `E007` | Потеря данных формы и плохой UX | Сохранять значения полей и тестировать retry-flow | Ошибки при повторном submit |

## Stop Conditions / Fallback

| Stop ID | Related refs | Trigger | Immediate action | Safe fallback state |
| --- | --- | --- | --- | --- |
| `STOP-01` | `CON-01`, `AG-02` | Для реализации требуется новый gem | Остановить работу и запросить approval | Оставить только документы без кодовых изменений |
| `STOP-02` | `CON-03` | Выявлена необходимость менять файлы вне `ai-setup` | Остановить шаг и эскалировать | Заморозить выполнение на последнем валидном checkpoint |

## Готово для приемки

План считается выполненным, когда:
- пройдены `CP-01..CP-03`;
- зафиксированы `EVID-01`, `EVID-02`;
- выполнены `CHK-01`, `CHK-02` и подтверждены `EC-01..EC-03` из `feature.md`.
