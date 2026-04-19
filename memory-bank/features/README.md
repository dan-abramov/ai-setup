---
title: Feature Packages Index
doc_kind: feature
doc_function: index
purpose: Навигация по instantiated feature packages. Читать, чтобы найти существующую delivery-единицу или понять, где создавать новую.
derived_from:
  - ../dna/governance.md
  - ../flows/feature-flow.md
status: active
audience: humans_and_agents
---

# Feature Packages Index

Каталог `memory-bank/features/` хранит instantiated feature packages вида `FT-XXX/`.

Upstream product scope для текущих package-ов фиксируется в [`../prd/PRD-001-task-generator-mvp.md`](../prd/PRD-001-task-generator-mvp.md).

## Rules

- Каждый package создается по правилам из [`../flows/feature-flow.md`](../flows/feature-flow.md).
- Для bootstrap используй шаблоны из [`../flows/templates/feature/`](../flows/templates/feature/).
- Если feature реализует или существенно меняет устойчивый сценарий проекта, она должна ссылаться на соответствующий `UC-*` из [`../use-cases/README.md`](../use-cases/README.md).
- В шаблонном репозитории этот каталог может быть пустым. Это нормально.

## Naming

- Базовый формат: `FT-XXX/`
- Вместо `XXX` используй идентификатор, принятый в проекте: issue id, ticket id или другой стабильный ключ
- Один package = одна delivery-единица

## Instantiated Packages

- [`FT-001/`](FT-001/README.md)
  Выбор `skill/topic` перед генерацией задачи. Canonical: `feature.md`, derived: `implementation-plan.md`.

- [`FT-002/`](FT-002/README.md)
  Генерация `task_description` с контрактом `E201-E209` и state machine `EMPTY/LOADING/SUCCESS/ERROR`.

- [`FT-003/`](FT-003/README.md)
  Повторное открытие задачи через `GET /task/:id` и контракт ошибок `E301-E303`.

- [`FT-010/`](FT-010/README.md)
  Удаление визуального статуса generation request во view-слое с сохранением submit/retry контрактов.

- [`FT-011/`](FT-011/README.md)
  Добавление поля ввода кода-решения на странице задачи (`/task/:id`) без внедрения проверки или сохранения решения.

- [`FT-012/`](FT-012/README.md)
  Сохранение введенного пользователем `solution_code` для задачи и восстановление значения при повторном открытии `/task/:id`.
