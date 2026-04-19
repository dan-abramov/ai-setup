---
title: "FT-010: Implementation Plan"
doc_kind: feature
doc_function: derived
purpose: "Execution-план реализации FT-010: убрать отображение статуса generation request из UI без изменения API/модели."
derived_from:
  - feature.md
status: active
audience: humans_and_agents
must_not_define:
  - ft_010_scope
  - ft_010_architecture
  - ft_010_acceptance_criteria
  - ft_010_blocker_state
---

# План имплементации

## Цель текущего плана

Убрать визуальный статус generation request из пользовательских view и сохранить текущий submit/retry контракт без регрессий.

## Current State / Reference Points

| Path / module | Current role | Why relevant | Reuse / mirror |
| --- | --- | --- | --- |
| `task_generator/app/views/generation_requests/new.html.erb` | Рендер формы и status-badge | Здесь показывается статус, который нужно убрать | Сохраняем существующую структуру формы и retry-кнопки |
| `task_generator/app/javascript/controllers/generation_request_form_controller.js` | Клиентская state machine и submit/retry | Сейчас контроллер обновляет `stateLabelTarget` | Сохраняем state machine, убираем зависимость от label target |
| `task_generator/app/assets/stylesheets/application.css` | Стили UI-компонентов формы | Возможны неиспользуемые стили статуса после изменения | Повторяем текущие стиль-конвенции проекта |
| `task_generator/spec/system/generation_request_flow_spec.rb` | Сквозной UI flow | Нужна проверка отсутствия статусного бейджа и сохранности flow | Использовать как главный acceptance suite |
| `task_generator/spec/requests/generation_requests_spec.rb` | API-контракт submit | Нельзя допустить дрейф JSON-контракта | Проверять неизменность `SUCCESS/ERROR` контрактов |
| `task_generator/README.md` | Публичное описание UI/API | Документация должна отражать новое UI-поведение | Синхронизировать после зеленых тестов |

## Test Strategy

| Test surface | Canonical refs | Existing coverage | Planned automated coverage | Required local suites / commands | Required CI suites / jobs | Manual-only gap / justification | Manual-only approval ref |
| --- | --- | --- | --- | --- | --- | --- | --- |
| UI без status-бейджа | `REQ-01`, `SC-01`, `NEG-01`, `CHK-01` | Есть system flow, ожидает текущий UI | Обновить `spec/system/generation_request_flow_spec.rb` под отсутствие status-блока | `cd task_generator && bundle exec rspec spec/system/generation_request_flow_spec.rb` | system / rspec | Короткий визуальный smoke для подтверждения UX | `AG-01` |
| API-контракт submit/reopen | `REQ-02`, `REQ-04`, `NEG-02`, `CHK-02` | request tests уже есть | Прогнать regression request suites без изменения контрактов | `cd task_generator && bundle exec rspec spec/requests/generation_requests_spec.rb spec/requests/tasks_spec.rb` | requests / rspec | none | none |

## Open Questions / Ambiguities

| Open Question ID | Question | Why unresolved | Blocks | Default action / escalation owner |
| --- | --- | --- | --- | --- |
| `OQ-01` | Под "на любой view" нужно убрать только текстовый status-бейдж или любой визуальный индикатор процесса тоже? | Issue #10 не содержит `body` | `STEP-02`, `STEP-03` | По умолчанию убрать именно status-текст/бейдж, оставить базовую UX-обратную связь кнопкой и error messages; при несоответствии уточнить у владельца issue |

## Environment Contract

| Area | Contract | Used by | Failure symptom |
| --- | --- | --- | --- |
| setup | Rails app поднят, зависимости и БД подготовлены | `STEP-01..STEP-07` | Спеки падают до целевой логики |
| test | Каноничный verify через `bundle exec rspec` на system/request уровнях | `STEP-05`, `STEP-06` | Нет доказательства выполнения `EC-*` |
| access / network / secrets | Для фичи внешний API не обязателен, тесты должны быть детерминированными | `STEP-05`, `STEP-06` | Флакки/сетевые падения в UI regressions |

## Preconditions

| Precondition ID | Canonical ref | Required state | Used by steps | Blocks start |
| --- | --- | --- | --- | --- |
| `PRE-01` | `CON-01`, `CON-02` | Без новых gem и без изменений вне `ai-setup` | `STEP-01..STEP-08` | yes |
| `PRE-02` | `OQ-01` | Зафиксирована трактовка: убираем status-бейдж, не ломая state machine | `STEP-02`, `STEP-03` | yes |

## Workstreams

| Workstream | Implements | Result | Owner | Dependencies |
| --- | --- | --- | --- | --- |
| `WS-1` | `REQ-01`, `REQ-03` | View/JS перестают показывать статус и остаются рабочими | agent | `PRE-01`, `PRE-02` |
| `WS-2` | `REQ-02`, `REQ-04` | Regression coverage и docs синхронизированы | agent | `WS-1` |

## Approval Gates

| Approval Gate ID | Trigger | Applies to | Why approval is required | Approver / evidence |
| --- | --- | --- | --- | --- |
| `AG-01` | Если UI smoke остаётся manual-only для части сценария | `STEP-06` | Нужна явная фиксация manual gap | human approval в issue/review |

## Порядок работ

| Step ID | Actor | Implements | Goal | Touchpoints | Artifact | Verifies | Evidence IDs | Check command / procedure | Blocked by | Needs approval | Escalate if |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `STEP-01` | agent | `REQ-01`, `REQ-03` | Зафиксировать все места, где UI рендерит/обновляет status | `new.html.erb`, Stimulus controller, CSS | Discovery notes в PR/комментарии | `CHK-01` | `EVID-01` | code search + inspection | `PRE-01` | none | Найдены дополнительные view за пределами текущего flow |
| `STEP-02` | agent | `REQ-01` | Удалить status-бейдж и связанные data-target из view | `new.html.erb` | Обновлённый шаблон формы | `CHK-01` | `EVID-01` | system test + manual open page | `STEP-01`, `PRE-02` | none | Трактовка issue конфликтует с ожиданиями владельца |
| `STEP-03` | agent | `REQ-03` | Убрать зависимость Stimulus от `stateLabelTarget` без потери логики | `generation_request_form_controller.js` | Обновлённый controller | `CHK-01` | `EVID-01` | system test | `STEP-02` | none | Возникают JS runtime errors в flow |
| `STEP-04` | agent | `REQ-01`, `REQ-04` | Удалить/адаптировать неиспользуемые стили и тексты статуса | `application.css`, locale files (если нужно) | UI не содержит legacy status-артефактов | `CHK-01` | `EVID-01` | targeted regression | `STEP-03` | none | Удаление текстов ломает другие экраны |
| `STEP-05` | agent | `REQ-02`, `REQ-04` | Обновить и прогнать system coverage | `spec/system/generation_request_flow_spec.rb` | Зеленый UI regression | `CHK-01` | `EVID-01` | `cd task_generator && bundle exec rspec spec/system/generation_request_flow_spec.rb` | `STEP-04` | none | Невозможно доказать сохранность сценариев через system tests |
| `STEP-06` | agent | `REQ-02`, `REQ-04` | Прогнать request regression на неизменность API-контрактов | `spec/requests/*.rb` | Зеленый request regression | `CHK-02` | `EVID-02` | `cd task_generator && bundle exec rspec spec/requests/generation_requests_spec.rb spec/requests/tasks_spec.rb` | `STEP-05` | `AG-01` (если есть manual-only gap) | Обнаружен дрейф `SUCCESS/ERROR` payload |
| `STEP-07` | agent | `REQ-04` | Синхронизировать `task_generator/README.md` с новым UI-контрактом | `task_generator/README.md` | Актуальная документация | `CHK-02` | `EVID-02` | doc review against tests | `STEP-06` | none | README расходится с фактическим поведением |
| `STEP-08` | agent | `REQ-01..REQ-04` | Выполнить финальный smoke и собрать evidence | test logs + smoke notes | Полный пакет evidence `EVID-01..03` | `CHK-03` | `EVID-03` | manual smoke: success + retryable error | `STEP-07` | `AG-01` | UI-поведение неоднозначно без уточнения issue-owner |

## Parallelizable Work

- `PAR-01` `STEP-04` (стили/локали) можно частично вести параллельно с подготовкой `STEP-05`.
- `PAR-02` Черновик `STEP-07` можно начать до финального прогона тестов, финализировать после `STEP-06`.

## Checkpoints

| Checkpoint ID | Refs | Condition | Evidence IDs |
| --- | --- | --- | --- |
| `CP-01` | `STEP-01..STEP-04` | UI больше не рендерит status-бейдж, JS стабилен | `EVID-01` |
| `CP-02` | `STEP-05..STEP-06` | System/request regression зелёные | `EVID-01`, `EVID-02` |
| `CP-03` | `STEP-07..STEP-08` | Docs и smoke подтверждают итоговый контракт | `EVID-02`, `EVID-03` |

## Execution Risks

| Risk ID | Risk | Impact | Mitigation | Trigger |
| --- | --- | --- | --- | --- |
| `ER-01` | Удаление status UI ломает Stimulus lifecycle | JS-ошибки, недоступный submit/retry | Удалять связки view+controller атомарно и сразу прогонять system test | Ошибки в браузерной консоли/падение system spec |
| `ER-02` | Неполный scope трактовки issue #10 | Неверная реализация относительно ожиданий владельца | Явно зафиксировать assumption `OQ-01` и эскалировать при несоответствии | Review feedback от owner |
| `ER-03` | Документация останется в старом состоянии | Рассинхрон между кодом и memory-bank/readme | Обязательный `STEP-07` после зеленых тестов | README упоминает старый status-badge |

## Stop Conditions / Fallback

| Stop ID | Related refs | Trigger | Immediate action | Safe fallback state |
| --- | --- | --- | --- | --- |
| `STOP-01` | `OQ-01` | Выяснилось, что требуется удалить всю прогресс-индикацию, а не только status-текст | Остановить реализацию и уточнить scope в issue | Вернуться к последнему зеленому checkpoint |
| `STOP-02` | `CON-01`, `CON-02` | Для решения понадобились внешние зависимости или изменения вне проекта | Эскалировать и не продолжать автономно | Зафиксировать blocker в feature docs |

## Готово для приемки

План считается выполненным, когда:
- пройдены `CP-01..CP-03`;
- собраны `EVID-01..EVID-03`;
- подтверждены `EC-01..EC-03` из `feature.md`.
