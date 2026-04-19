---
title: "FT-003: Feature Package"
doc_kind: feature
doc_function: index
purpose: "Bootstrap-safe навигация по документации FT-003. Сначала направляет к canonical `feature.md`, затем к execution-плану."
derived_from:
  - ../../dna/governance.md
  - feature.md
status: active
audience: humans_and_agents
---

# FT-003: Feature Package

## О разделе

Каталог хранит canonical описание фичи повторного открытия задачи по URL и связанный execution-план.

## Аннотированный индекс

- [`feature.md`](feature.md)
  Читать, когда нужно: проверить scope, контракт `POST /generation_requests` + `GET /task/:id`, ошибки `E301-E303` и AC FT-003.
  Отвечает на вопрос: что должно быть реализовано для reopen-сценария.

- [`implementation-plan.md`](implementation-plan.md)
  Читать, когда нужно: выполнить реализацию FT-003 по шагам с привязкой к проверкам и evidence.
  Отвечает на вопрос: как внедрять изменения без выхода за границы модулей.

- [Issue #7](https://github.com/dan-abramov/ai-setup/issues/7)
  Читать, когда нужно: сверить package с исходной постановкой в tracker.
