---
title: "FT-002: Implementation Plan"
doc_kind: feature
doc_function: derived
purpose: "Execution-план реализации FT-002: генерация `task_description`, валидация результата, HTTP/UI контракт и метрики качества."
derived_from:
  - feature.md
status: active
audience: humans_and_agents
must_not_define:
  - ft_002_scope
  - ft_002_architecture
  - ft_002_acceptance_criteria
  - ft_002_blocker_state
---

# План имплементации

## Цель текущего плана

Реализовать полный pipeline генерации описания задачи по `skill/topic` с контрактом ошибок `E201-E209`, state machine UI и проверкой целевых метрик `p95/success_rate`.

## Current State / Reference Points

| Path / module | Current role | Why relevant | Reuse / mirror |
| --- | --- | --- | --- |
| `task_generator/app/models/generation_request.rb` | Входные данные запроса | Нужны поля/статусы результата и контракт valid request | Повторить подход нормализации из FT-001 |
| `task_generator/app/services/generation/` | Сервисный слой генерации | Нужны `AiClient`, `DescriptionValidator`, `BuildDescriptionService` | Следовать service object conventions |
| `task_generator/app/controllers/generation_requests_controller.rb` | Submit endpoint | Нужно зафиксировать JSON-контракт `SUCCESS/ERROR` | Сохранить явный маппинг error_code |
| `task_generator/app/controllers/generation_flow_controller.rb` | Шаг перехода | Нужны guard и endpoint `metrics` | Не ломать существующий flow |
| `task_generator/app/javascript/controllers/generation_request_form_controller.js` | UI state machine | Нужно синхронизировать состояния с API-контрактом | Mirror существующий Stimulus стиль |
| `task_generator/config/initializers/` | Runtime config | Нужна OpenRouter-конфигурация и timeout | Использовать `Rails.application.config.x.*` |
| `task_generator/spec/` | Тесты | Нужно покрыть `AC-01..AC-08` | Распределить тесты по слоям model/service/request/system |

## Test Strategy

| Test surface | Canonical refs | Existing coverage | Planned automated coverage | Required local suites / commands | Required CI suites / jobs | Manual-only gap / justification | Manual-only approval ref |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `GenerationRequest` + input errors | `REQ-01`, `REQ-02`, `NEG-01`, `CHK-01` | Частично из FT-001 | Дополнить `E201-E203`, отсутствие persist на input error | `cd task_generator && bundle exec rspec spec/models/generation_request_spec.rb` | Rails RSpec | none | none |
| `AiClient`, `DescriptionValidator`, `BuildDescriptionService` | `REQ-01`, `REQ-02`, `SC-02`, `SC-03`, `NEG-02`, `CHK-01` | Нет/частично | Полный unit/service coverage primary/fallback/timeout/validator | `cd task_generator && bundle exec rspec spec/services` | Rails RSpec | none | none |
| `POST /generation_requests` contract + UI states | `REQ-03`, `REQ-04`, `SC-01`, `SC-02`, `SC-03`, `CHK-02` | Частично | Request/system тесты на `200/422`, retry rules, guard flow | `cd task_generator && bundle exec rspec spec/requests spec/system` | Rails RSpec/System | none | none |
| `GET /generation_flow/metrics` | `REQ-05`, `SC-04`, `CHK-03` | Нет | Request test + data-window scenario 200 запросов | `cd task_generator && bundle exec rspec spec/requests/generation_flow_spec.rb` | Rails RSpec | Возможно ручной performance-smoke для p95 | `AG-01` |

## Open Questions / Ambiguities

| Open Question ID | Question | Why unresolved | Blocks | Default action / escalation owner |
| --- | --- | --- | --- | --- |
| `OQ-01` | Нужна ли отдельная persistent-метрика, кроме endpoint `generation_flow/metrics` | Зависит от продуктового решения по аналитике | `STEP-11`, `STEP-14` | По умолчанию ограничиться endpoint из scope; эскалировать при требовании long-term хранения |

## Environment Contract

| Area | Contract | Used by | Failure symptom |
| --- | --- | --- | --- |
| setup | Rails app и БД готовы, миграции применяются локально | `STEP-01`, `STEP-02` | Невозможность создать/обновить `GenerationRequest` |
| test | Эталонные verify-команды: `bundle exec rspec` по services/requests/system | `STEP-12`, `STEP-13` | Нельзя доказать AC-01..AC-08 |
| access / network / secrets | Для runtime нужны `OPENROUTER_API_KEY` и timeout env; в тестах API вызовы стабируются stub/mock | `STEP-03`, `STEP-04` | Флакки/сетевые падения вместо детерминированных ошибок |

## Preconditions

| Precondition ID | Canonical ref | Required state | Used by steps | Blocks start |
| --- | --- | --- | --- | --- |
| `PRE-01` | `CON-01`, `CON-02` | Без новых gem, реализация только в текущем Rails стеке | `STEP-01..STEP-14` | yes |
| `PRE-02` | `CON-04` | Доступна конфигурация OpenRouter и поддержка timeout | `STEP-03`, `STEP-04`, `STEP-06` | yes |
| `PRE-03` | `ASM-01` | Входной шаг `skill/topic` уже поставляет нормализуемые данные | `STEP-02`, `STEP-06`, `STEP-09` | yes |

## Workstreams

| Workstream | Implements | Result | Owner | Dependencies |
| --- | --- | --- | --- | --- |
| `WS-1` | `REQ-01`, `REQ-02` | Серверный pipeline генерации и валидации | agent | `PRE-01`, `PRE-02` |
| `WS-2` | `REQ-03`, `REQ-04` | HTTP/UI контракт и guard перехода | agent | `WS-1`, `PRE-03` |
| `WS-3` | `REQ-05` | Метрики `p95/success_rate` и verify сценарий | agent | `WS-1` |
| `WS-4` | `REQ-01..REQ-05` | Тесты и документация | agent | `WS-1`, `WS-2`, `WS-3` |

## Approval Gates

| Approval Gate ID | Trigger | Applies to | Why approval is required | Approver / evidence |
| --- | --- | --- | --- | --- |
| `AG-01` | Нужен manual-only perf-check для `p95` вместо автоматизации | `STEP-11`, `STEP-13` | Manual gap должен быть явно подтвержден | human approval в issue/review |
| `AG-02` | Появилась необходимость добавить gem или изменить модуль вне scope | `STEP-01..STEP-14` | Нарушает `CON-01`/`CON-03` | human decision в tracker |

## Порядок работ

| Step ID | Actor | Implements | Goal | Touchpoints | Artifact | Verifies | Evidence IDs | Check command / procedure | Blocked by | Needs approval | Escalate if |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `STEP-01` | agent | `REQ-01` | Добавить поля результата в `generation_requests` | `db/migrate/*_add_generation_result_fields_to_generation_requests.rb`, `db/schema.rb` | Поля `task_description/status/error_code/latency_ms` | `CHK-01` | `EVID-01` | `cd task_generator && bin/rails db:migrate && bin/rails db:schema:dump` | `PRE-01` | none | Миграция ломает существующую схему |
| `STEP-02` | agent | `REQ-01`, `REQ-02` | Обновить `GenerationRequest` под `valid request` | `app/models/generation_request.rb` | Валидации `E201-E203`, helper codes | `CHK-01` | `EVID-01` | `bin/rails runner` smoke валидаций | `STEP-01`, `PRE-03` | none | Нельзя выразить contract без breaking change |
| `STEP-03` | agent | `REQ-01` | Добавить runtime-конфигурацию OpenRouter | `config/initializers/generation.rb`, `README.md` | Config contract + `E205` для missing key | `CHK-01` | `EVID-01` | `bin/rails runner 'puts Rails.application.config.x.generation.openrouter_timeout_seconds'` | `PRE-02` | none | Env contract конфликтует с deployment |
| `STEP-04` | agent | `REQ-01` | Реализовать `Generation::AiClient` | `app/services/generation/ai_client.rb` | Primary/fallback + timeout map `E204/E205` | `CHK-01` | `EVID-01` | Service spec with HTTP stubs | `STEP-03` | none | Provider contract отличается от ожидаемого |
| `STEP-05` | agent | `REQ-02` | Реализовать `DescriptionValidator` | `app/services/generation/description_validator.rb` | Проверки `E206-E209` | `CHK-01` | `EVID-01` | Service spec validator cases | `STEP-04` | none | Невозможно выразить инвариант без смены scope |
| `STEP-06` | agent | `REQ-01`, `REQ-02` | Оркестровать `submit -> generation -> validate -> persist` | `app/services/generation/build_description_service.rb`, `app/services/generation_requests/submit_service.rb` | End-to-end pipeline | `CHK-01`, `CHK-02` | `EVID-01`, `EVID-02` | Service specs on success/errors | `STEP-02`, `STEP-04`, `STEP-05` | none | Нельзя сохранить backwards-совместимость ошибок |
| `STEP-07` | agent | `REQ-03` | Зафиксировать HTTP-контракт submit | `app/controllers/generation_requests_controller.rb`, `config/routes.rb` | `200 SUCCESS` / `422 ERROR` JSON | `CHK-02` | `EVID-02` | Request specs + route check | `STEP-06` | none | Контракт не покрывает required error branches |
| `STEP-08` | agent | `REQ-04` | Добавить `GenerationFlow` guard endpoint | `app/controllers/generation_flow_controller.rb`, `app/views/generation_flow/show.html.erb`, `config/routes.rb` | Guarded `GET /generation_flow/:id` | `CHK-02` | `EVID-02` | Request/system flow test | `STEP-07` | none | Guard требует out-of-scope изменений |
| `STEP-09` | agent | `REQ-03`, `REQ-04` | Обновить UI state machine | `app/views/generation_requests/new.html.erb`, `app/javascript/controllers/generation_request_form_controller.js`, `app/assets/stylesheets/application.css` | UI `EMPTY/LOADING/SUCCESS/ERROR` + retry rules | `CHK-02` | `EVID-02` | System specs and manual smoke | `STEP-07`, `STEP-08` | none | UI не может отразить контракт без redesign |
| `STEP-10` | agent | `REQ-03` | Добавить i18n тексты `E201-E209` | `config/locales/ru.yml`, `config/locales/en.yml` | Локализованные сообщения/кнопки/состояния | `CHK-02` | `EVID-02` | Locale request/system checks | `STEP-09` | none | Локали конфликтуют со старыми ключами |
| `STEP-11` | agent | `REQ-05` | Реализовать endpoint метрик | `app/controllers/generation_flow_controller.rb`, `config/routes.rb` | `GET /generation_flow/metrics` | `CHK-03` | `EVID-03` | Request smoke на данных >=200 | `STEP-01`, `OQ-01` | `AG-01` (если manual perf only) | Нужна persistent analytics вне scope |
| `STEP-12` | agent | `REQ-01`, `REQ-02` | Обновить unit/service coverage | `spec/models`, `spec/services`, `spec/factories` | Покрытие `E201-E209`, fallback, latency fields | `CHK-01` | `EVID-01` | `cd task_generator && bundle exec rspec spec/models spec/services` | `STEP-11` | none | Критичные ошибки остаются без deterministic tests |
| `STEP-13` | agent | `REQ-03`, `REQ-04`, `REQ-05` | Обновить request/system coverage | `spec/requests`, `spec/system` | Контракты `200/422`, flow guard, metrics, UI states | `CHK-02`, `CHK-03` | `EVID-02`, `EVID-03` | `cd task_generator && bundle exec rspec spec/requests spec/system` | `STEP-12` | `AG-01` (если perf gap manual) | Невозможно проверить AC-08 автоматически |
| `STEP-14` | agent | `REQ-01..REQ-05` | Актуализировать README | `task_generator/README.md` | Документация API/state/errors/metrics | `CHK-02`, `CHK-03` | `EVID-02`, `EVID-03` | Doc review against tests | `STEP-13` | none | README расходится с фактическим контрактом |

## Parallelizable Work

- `PAR-01` `STEP-03` (config) и `STEP-02` (model contract) можно вести параллельно после `STEP-01`.
- `PAR-02` `STEP-10` (локали) можно начинать после стабилизации `STEP-07`, не дожидаясь `STEP-11`.
- `PAR-03` Черновик `STEP-14` можно вести параллельно `STEP-12/STEP-13`, финализация после зелёных тестов.

## Checkpoints

| Checkpoint ID | Refs | Condition | Evidence IDs |
| --- | --- | --- | --- |
| `CP-01` | `STEP-01..STEP-06`, `CHK-01` | Pipeline генерации и валидации стабилен | `EVID-01` |
| `CP-02` | `STEP-07..STEP-10`, `CHK-02` | HTTP/UI контракт соответствует `SUCCESS/ERROR` | `EVID-02` |
| `CP-03` | `STEP-11`, `CHK-03` | Метрики `p95/success_rate` доступны и проверяемы | `EVID-03` |
| `CP-04` | `STEP-12..STEP-14` | Полный regression зелёный, docs синхронизированы | `EVID-01`, `EVID-02`, `EVID-03` |

## Execution Risks

| Risk ID | Risk | Impact | Mitigation | Trigger |
| --- | --- | --- | --- | --- |
| `ER-01` | Флакки из-за реальных сетевых вызовов OpenRouter в тестах | Нестабильные CI/local результаты | Использовать stubs/mocks в service tests | Случайные падения по timeout/network |
| `ER-02` | Несогласованность retry-логики UI и API | Некорректное поведение пользователя в `ERROR` | Фиксировать retry matrix в request+system тестах | UI показывает retry не для тех кодов |
| `ER-03` | Ошибка маршрутизации `generation_flow/metrics` vs `generation_flow/:id` | Невалидные ответы на metrics endpoint | Объявить статический route выше динамического | 404/неправильный контроллер для metrics |

## Stop Conditions / Fallback

| Stop ID | Related refs | Trigger | Immediate action | Safe fallback state |
| --- | --- | --- | --- | --- |
| `STOP-01` | `CON-01`, `AG-02` | Потребовался новый gem | Остановить реализацию и запросить решение человека | Оставить только documentation update |
| `STOP-02` | `CON-03` | Требуется изменение за пределами допустимых модулей | Зафиксировать blocker и эскалировать | Сохранить рабочее состояние до последнего checkpoint |
| `STOP-03` | `OQ-01` | Требуют persistent analytics вне scope FT-002 | Остановить `STEP-11` и поднять отдельную фичу | Выполнить только текущий endpoint метрик |

## Готово для приемки

План считается выполненным, когда:
- пройдены `CP-01..CP-04`;
- собраны `EVID-01..EVID-03`;
- подтверждены `EC-01..EC-03` из `feature.md` и AC-01..AC-08.
