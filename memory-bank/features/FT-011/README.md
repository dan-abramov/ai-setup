---
title: "FT-011: Feature Package"
doc_kind: feature
doc_function: index
purpose: "Bootstrap-safe навигация по документации FT-011. Сначала направляет к canonical `feature.md`, затем к execution-плану."
derived_from:
  - ../../dna/governance.md
  - feature.md
status: active
audience: humans_and_agents
---

# FT-011: Feature Package

## О разделе

Каталог хранит canonical описание фичи добавления поля ввода кода-решения на странице задачи и связанный execution-план.

## Аннотированный индекс

- [`feature.md`](feature.md)
  Читать, когда нужно: проверить scope, ограничения и verify-контракт по добавлению input для пользовательского кода.
  Отвечает на вопрос: что именно должно появиться на `/task/:id` и что пока не входит в фичу.

- [`implementation-plan.md`](implementation-plan.md)
  Читать, когда нужно: выполнить реализацию FT-011 по шагам с привязкой к проверкам и evidence.
  Отвечает на вопрос: как внедрить новое поле ввода без регрессий reopen/API контрактов.

- [Issue #11](https://github.com/dan-abramov/ai-setup/issues/11)
  Читать, когда нужно: сверить package с исходной постановкой в tracker.
