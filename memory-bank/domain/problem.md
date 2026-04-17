---
title: Project Problem Statement (Task Generator)
doc_kind: domain
doc_function: canonical
purpose: Каноничное описание продукта task_generator, проблемного пространства и целевых outcomes. Читать перед feature-спеками, чтобы не повторять общий контекст в каждой delivery-единице.
derived_from:
  - ../dna/governance.md
status: active
audience: humans_and_agents
canonical_for:
  - project_problem_statement
  - product_context
  - top_level_outcomes
---

# Project Problem Statement

Этот документ фиксирует общий продуктовый контекст учебного проекта `task_generator`. Feature-документы должны ссылаться на него, а не переписывать один и тот же background каждый раз.

PRD, если он нужен, не заменяет этот документ, а уточняет отдельную инициативу относительно уже зафиксированного project-wide контекста.

## Boundary With PRD

- `domain/problem.md` — общий для всего проекта контекст: продукт, ключевые workflows, top-level outcomes и устойчивые ограничения.
- `prd/PRD-XXX-short-name.md` — инициативный слой: какая именно продуктовая проблема берется в работу сейчас, для каких пользователей и с каким scope.
- Если новый документ просто повторяет общий фон проекта и не вводит initiative-specific scope, PRD создавать не нужно.

## Product Context

`task_generator` помогает пользователю быстро получить короткое описание Ruby-задачи под конкретный навык (`skill`) и тему (`topic`). Ключевая цель продукта: сократить время от идеи тренировки до старта решения.

Система берет два поля ввода, вызывает AI-провайдера (OpenRouter), валидирует и сохраняет результат как `Task`. После успешной генерации пользователь сразу перенаправляется на страницу задачи, а затем может повторно открыть ее по постоянному URL `/task/:id` без нового AI-вызова.

Проект намеренно ограничен: одно короткое описание до 150 символов, небольшой набор стабильных error codes (`E201-E209`, `E301-E303`) и простая web-форма без сложного аккаунтинга, очередей и multi-user collaborative сценариев.

## Core Workflows

- `WF-01` Пользователь открывает `/generation_requests/new`, вводит `skill` и `topic`, отправляет форму и получает `SUCCESS` с redirect на `/task/:id`.
- `WF-02` При ошибке генерации пользователь видит конкретный `error_code`; для `E204-E209` и `E301` доступен retry без перезагрузки страницы.
- `WF-03` Повторное открытие уже созданной задачи по URL `/task/:id` не запускает новую генерацию и не создает `GenerationRequest`.
- `WF-04` Операционный мониторинг через `GET /generation_flow/metrics` на окне последних 200 валидных запросов (`SUCCESS`/`ERROR` c `latency_ms`).

## Outcomes

| Metric ID | Metric | Baseline | Target | Measurement method |
| --- | --- | --- | --- | --- |
| `MET-01` | P95 latency генерации | пока не зафиксирован на production-данных | `<= 1000ms` | `GET /generation_flow/metrics` -> `p95_latency_ms` |
| `MET-02` | Успешность генерации | пока не зафиксирована на production-данных | `>= 95.0%` | `GET /generation_flow/metrics` -> `success_rate` |
| `MET-03` | Надежность повторного открытия задач | baseline не зафиксирован отдельно, проверяется тестами | `>= 95%` в окне из 200 открытий | request/system тесты AC-07/AC-08 |

## Constraints

- `PCON-01` Входные поля `skill/topic` обязательны после sanitize+trim и ограничены 100 символами; ошибки ввода маппятся на `E201-E203` без записи в БД.
- `PCON-02` Генерируемое описание сохраняется как plain text до 150 символов (`Task::MAX_DESCRIPTION_LENGTH`); недоступные/пустые задачи должны отдавать `E303`.
- `PCON-03` Интеграция с AI синхронная внутри HTTP-запроса, зависит от конфигурации OpenRouter (`OPENROUTER_*`) и таймаута `OPENROUTER_TIMEOUT_SECONDS`.
- `PCON-04` Контракт ошибок является публичным для UI и тестов; нельзя менять семантику `E201-E209`, `E301-E303` без синхронного обновления фронта, тестов и документации.
- `PCON-05` `GET /task/:id` и `GET /generation_flow/:id` не инициируют генерацию; эти endpoint-ы только читают ранее сохраненное состояние.

## Source Documents

- [`../../PROJECT.md`](../../PROJECT.md)
- [`../../task_generator/README.md`](../../task_generator/README.md)
- Кодовые контракты: `task_generator/app/services/generation/*`, `task_generator/app/services/generation_requests/submit_service.rb`, `task_generator/app/controllers/*`
- Проверка AC-контрактов: `task_generator/spec/requests/*.rb`, `task_generator/spec/system/*.rb`
