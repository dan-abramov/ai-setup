---
title: "FT-012: Feature Package"
doc_kind: feature
doc_function: index
purpose: "Bootstrap-safe навигация по документации FT-012. Сначала направляет к canonical `feature.md`, затем к execution-плану."
derived_from:
  - ../../dna/governance.md
  - feature.md
status: active
audience: humans_and_agents
---

# FT-012: Feature Package

## О разделе

Каталог хранит canonical описание фичи сохранения пользовательского кода-решения и связанный execution-план.

## Аннотированный индекс

- [`feature.md`](feature.md)
  Читать, когда нужно: проверить scope, ограничения и verify-контракт по сохранению `solution_code` для задачи.
  Отвечает на вопрос: что именно считается "сохранением решения" в рамках issue #12 и что остается вне scope.

- [`implementation-plan.md`](implementation-plan.md)
  Читать, когда нужно: выполнить реализацию FT-012 по шагам с привязкой к проверкам и evidence.
  Отвечает на вопрос: как добавить persistence без регрессий существующего generation/reopen потока.

- [Issue #12](https://github.com/dan-abramov/ai-setup/issues/12)
  Читать, когда нужно: сверить package с исходной постановкой в tracker.
