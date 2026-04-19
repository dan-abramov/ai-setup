---
title: Git Workflow
doc_kind: engineering
doc_function: convention
purpose: Git workflow для репозитория ai-setup и вложенного Rails-проекта task_generator.
derived_from:
  - ../dna/governance.md
status: active
audience: humans_and_agents
---

# Git Workflow

## Default Branch

Основная ветка репозитория: `main`.

## Commits

- Один commit = одно логически цельное изменение.
- Сообщение коммита короткое и предметное (например: `hw-2`, `fix generation flow`, `docs: update testing policy`).
- Не смешивай в одном коммите несвязанные изменения (например, фича + случайный рефактор).
- Если меняется контракт или поведение, commit message должен явно это отражать.

## Pull Requests

- Перед PR должны быть зелёными canonical local checks затронутой части проекта.
- Для изменений в `task_generator` обязательный минимум: `bundle exec rspec`.
- Если изменены только docs/infra-файлы, укажи в PR, почему Rails-сьют не запускался.
- PR title короткий и предметный; в body фиксируй:
  - что изменено;
  - как проверено;
  - какие риски/ограничения остаются.
- Текущий CI не запускает Rails-спеки автоматически, поэтому результат локального прогона тестов обязательно указывается в PR-описании.

## Worktrees

Worktrees не являются обязательной частью workflow.

Если worktree используется:

- он создается как отдельная рабочая копия рядом с репозиторием;
- изменения вносятся только в рамках нужного worktree;
- запрещено редактировать файлы вне проекта.
