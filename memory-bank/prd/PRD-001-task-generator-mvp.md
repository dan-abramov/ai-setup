---
title: "PRD-001: Task Generator MVP"
doc_kind: prd
doc_function: canonical
purpose: "Фиксирует продуктовую инициативу MVP генерации задач: users/jobs, goals, scope, правила и метрики успеха."
derived_from:
  - ../domain/problem.md
  - ../../PRD.md
status: active
audience: humans_and_agents
must_not_define:
  - implementation_sequence
  - architecture_decision
  - feature_level_verify_contract
---

# PRD-001: Task Generator MVP

## Problem

Пользователь хочет быстро перейти к тренировке конкретного Ruby-навыка на интересной ему теме, но ручное составление задачи занимает слишком много времени. Нужен короткий предсказуемый путь от ввода `skill/topic` до готовой задачи.

## Users And Jobs

| User / Segment | Job To Be Done | Current Pain |
| --- | --- | --- |
| `junior-ruby-student` | Быстро получить задачу под нужный навык | Сложно и долго придумывать формулировку задачи |
| `self-learner` | Вернуться к уже сгенерированной задаче позже | После закрытия вкладки задача теряется |

## Goals

- `G-01` Сократить время от идеи тренировки до получения задачи, готовой к решению.
- `G-02` Обеспечить предсказуемый error-contract генерации.
- `G-03` Сделать reopen задачи по постоянному URL без повторного AI-вызова.

## Non-Goals

- `NG-01` Проверка пользовательского решения и оценка качества кода.
- `NG-02` История задач, рекомендации и персонализация.
- `NG-03` Мультипользовательский режим и сложные права доступа.

## Product Scope

### In Scope

- Веб-форма ввода `skill/topic`.
- Генерация короткого `task_description` с post-валидацией.
- Контракт ошибок `E201-E209`, `E301-E303`.
- Создание и повторное открытие `Task` по `/task/:id`.
- Метрики `p95` и `success_rate` на окне последних 200 валидных запросов.

### Out Of Scope

- Асинхронные очереди и распределённая оркестрация.
- Профили пользователей и история решений.
- Любые форматы задач, кроме Ruby-ориентированного MVP.

## UX / Business Rules

- `BR-01` `skill/topic` обязательны после sanitize+trim, длина до 100 символов.
- `BR-02` Результат генерации после normalize ограничен 150 символами.
- `BR-03` UI поддерживает `EMPTY/LOADING/SUCCESS/ERROR`; retry только для recoverable ошибок.
- `BR-04` `GET /task/:id` всегда read-only и не запускает новую генерацию.

## Success Metrics

| Metric ID | Metric | Baseline | Target | Measurement method |
| --- | --- | --- | --- | --- |
| `MET-01` | Success rate генерации | не зафиксирован | `>= 95%` | `GET /generation_flow/metrics` |
| `MET-02` | P95 latency генерации | не зафиксирован | `<= 1000ms` | `GET /generation_flow/metrics` |
| `MET-03` | Успешное reopen задачи | `0%` до FT-003 | `>= 95%` | request/system тесты |

## Risks And Open Questions

- `RISK-01` Нестабильный провайдер может увеличивать `E204/E205`.
- `RISK-02` Жёсткие правила валидатора могут повышать `E206-E209`.
- `OQ-01` Нужен ли отдельный аналитический слой для долгосрочного хранения метрик.

## Downstream Features

| Feature | Why it exists | Status |
| --- | --- | --- |
| `FT-001` | Ввод и валидация `skill/topic` | done |
| `FT-002` | Генерация `task_description` и контракт ошибок | done |
| `FT-003` | Создание `Task` и reopen-flow | done |
| `FT-010` | Убрать визуальный статус generation request на пользовательских view | done |
| `FT-011` | Добавить input для ввода кода-решения на странице `/task/:id` | done |
| `FT-012` | Сохранять код-решение, введенный пользователем, на странице `/task/:id` | done |
