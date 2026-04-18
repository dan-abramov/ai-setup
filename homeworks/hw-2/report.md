# HW-2 Report

## Что сделано

- Адаптирован `memory-bank/` под проект `task_generator` с разделением на слои `domain / prd / features / engineering / ops`.
- Добавлен product-level PRD:
  - `PRD.md`
  - `memory-bank/prd/PRD-001-task-generator-mvp.md`
- Сформирован routing-слой:
  - `AGENTS.md` (routing + ограничения)
  - `index.md` и `memory-bank/README.md` как точки входа.
- Вынесен prompt pack для прайминга flow в `.prompts/`.

## Артефакты feature-циклов (3 штуки)

- `memory-bank/features/FT-001/*`
- `memory-bank/features/FT-002/*`
- `memory-bank/features/FT-003/*`

Для каждой фичи есть как минимум:
- `feature.md` (canonical)
- `implementation-plan.md` (derived)
- `README.md` (локальная навигация)

## Чеклист соответствия HW-2

- [x] В проекте есть адаптированный `memory-bank/`.
- [x] Есть `PRD.md`, созданный на основе описания проекта.
- [x] `AGENTS.md` используется как routing-таблица, а не как knowledge dump.
- [x] Есть 3 feature-цикла в `memory-bank/features/`.
- [x] Есть `.prompts/` с праймингом по типовым процессам.

## Что сдавать

- Ссылку на репозиторий с текущим состоянием.
- Основные точки для проверки:
  - `AGENTS.md`
  - `PRD.md`
  - `memory-bank/README.md`
  - `memory-bank/prd/PRD-001-task-generator-mvp.md`
  - `memory-bank/features/README.md`
  - `.prompts/README.md`
