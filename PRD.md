# PRD: Task Generator MVP

## Problem

Пользователь хочет быстро потренировать конкретный Ruby-навык на интересной ему теме, но ручная подготовка задачи отнимает время. Из-за этого путь от идеи тренировки до начала решения слишком длинный и часто прерывается.

## Users And Jobs

| User / Segment | Job To Be Done | Current Pain |
| --- | --- | --- |
| `junior-ruby-student` | Получить задачу на нужный навык и тему за 1-2 шага | Нет быстрого способа сформулировать интересную задачу |
| `self-learner` | Возвращаться к уже сгенерированной задаче по ссылке | После закрытия вкладки задача теряется |

## Goals

- `G-01` Сократить время от ввода `skill/topic` до получения задачи, готовой к решению.
- `G-02` Сделать генерацию предсказуемой через стабильный контракт кодов ошибок.
- `G-03` Обеспечить повторное открытие сгенерированной задачи по постоянному URL.

## Non-Goals

- `NG-01` Не строить платформу проверки решений и хранения истории прогресса пользователя.
- `NG-02` Не добавлять персонализацию, рекомендации и мультипользовательские сценарии.
- `NG-03` Не выходить за рамки Ruby-задач в рамках текущего MVP.

## Product Scope

### In Scope

- Ввод `skill/topic` через веб-форму.
- Генерация краткого `task_description` через OpenRouter.
- Валидация результата и возврат ошибок `E201-E209`, `E301-E303`.
- Создание `Task` и повторное открытие по `GET /task/:id`.
- Метрики качества на окне последних 200 валидных запросов.

### Out Of Scope

- Регистрация/авторизация.
- История всех задач пользователя и поиск по ним.
- Асинхронные очереди и сложная оркестрация background jobs.

## UX / Business Rules

- `BR-01` `skill/topic` обязательны после sanitize+trim, длина `1..100`.
- `BR-02` Сгенерированное описание после normalize должно быть непустым и не длиннее 150 символов.
- `BR-03` UI работает через состояния `EMPTY/LOADING/SUCCESS/ERROR`; retry доступен для `E204-E209` и `E301`.
- `BR-04` `GET /task/:id` не инициирует новую генерацию.

## Success Metrics

| Metric ID | Metric | Baseline | Target | Measurement method |
| --- | --- | --- | --- | --- |
| `MET-01` | Success rate генерации | не зафиксирован | `>= 95%` | `GET /generation_flow/metrics` |
| `MET-02` | P95 latency генерации | не зафиксирован | `<= 1000ms` | `GET /generation_flow/metrics` |
| `MET-03` | Успешное повторное открытие задачи | `0%` до внедрения reopen-flow | `>= 95%` | request/system тесты + smoke |

## Risks And Open Questions

- `RISK-01` Нестабильность внешнего AI-провайдера может снижать success rate.
- `RISK-02` Жёсткие ограничения на длину/формат описания могут повышать долю `E206-E209`.
- `OQ-01` Нужна ли в следующей итерации связь `Task <-> GenerationRequest` на уровне отдельного FK и отчётности.

## Downstream Features

| Feature | Why it exists | Status |
| --- | --- | --- |
| `FT-001` | Обязательный ввод `skill/topic` и нормализация данных | done |
| `FT-002` | Генерация `task_description` и error contract `E201-E209` | done |
| `FT-003` | Создание `Task` и reopen по `/task/:id` | done |
| `FT-010` | Убрать визуальный статус generation request на пользовательских view | planned |
| `FT-011` | Добавить input для ввода кода-решения на странице `/task/:id` | planned |
| `FT-012` | Сохранять код-решение, введенный пользователем, на странице `/task/:id` | planned |

## Canonical Links

- Product context: `memory-bank/domain/problem.md`
- Initiative-level PRD in memory bank: `memory-bank/prd/PRD-001-task-generator-mvp.md`
- Feature registry: `memory-bank/features/README.md`
