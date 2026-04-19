---
title: "FT-010: Feature Package"
doc_kind: feature
doc_function: index
purpose: "Bootstrap-safe навигация по документации FT-010. Сначала направляет к canonical `feature.md`, затем к execution-плану."
derived_from:
  - ../../dna/governance.md
  - feature.md
status: active
audience: humans_and_agents
---

# FT-010: Feature Package

## О разделе

Каталог хранит canonical описание фичи по скрытию статуса генерации request в UI и связанный execution-план.

## Аннотированный индекс

- [`feature.md`](feature.md)
  Читать, когда нужно: проверить scope, ограничения и verify-контракт по удалению отображения статуса generation request во view-слое.
  Отвечает на вопрос: что именно должно измениться в UI и что не должно поменяться в API/модели.

- [`implementation-plan.md`](implementation-plan.md)
  Читать, когда нужно: выполнить реализацию FT-010 по шагам с привязкой к проверкам и evidence.
  Отвечает на вопрос: как внедрить изменение без регрессий submit/retry flow.

- [Issue #10](https://github.com/dan-abramov/ai-setup/issues/10)
  Читать, когда нужно: сверить package с исходной постановкой в tracker.
