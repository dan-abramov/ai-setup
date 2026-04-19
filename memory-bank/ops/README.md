---
title: Operations Index
doc_kind: engineering
doc_function: index
purpose: Навигация по операционной документации проекта task_generator в репозитории ai-setup.
derived_from:
  - ../dna/governance.md
status: active
audience: humans_and_agents
---

# Operations Index

Каталог `memory-bank/ops/` фиксирует operational contracts для текущего учебного приложения `task_generator` (Rails 7.1 + PostgreSQL + OpenRouter integration).

- [Development Environment](development.md) — canonical setup и ежедневные команды для локальной разработки.
- [Stages And Non-Local Environments](stages.md) — текущее состояние по non-local стендам и правила доступа.
- [Release And Deployment](release.md) — текущий release-flow, обязательные проверки и rollback-подход.
- [Configuration](config.md) — реальные env/runtime contracts (`OPENROUTER_*`, `RAILS_*`, `DATABASE_URL`).
- [Runbooks](runbooks/README.md) — индекс operational runbooks (в проекте пока только базовый каркас).
