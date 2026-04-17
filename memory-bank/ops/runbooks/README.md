---
title: Runbooks Index
doc_kind: engineering
doc_function: index
purpose: Индекс operational runbooks для task_generator. Используется при диагностике и восстановлении типовых сбоев.
derived_from:
  - ../../dna/governance.md
status: active
audience: humans_and_agents
---

# Runbooks Index

В этом каталоге живут runbooks для повторяемых operational задач `task_generator`.

Текущее состояние: выделенных runbook-файлов пока нет, кроме этого индекса.

Runbook должен отвечать на вопросы:

- что является триггером;
- что проверить сначала;
- какие команды выполнять;
- какой результат ожидать;
- как безопасно откатиться;
- кому и когда эскалировать проблему.

## Suggested Structure

1. Summary
2. Trigger / symptoms
3. Safety notes
4. Diagnosis
5. Resolution
6. Rollback
7. Escalation

Рекомендуемые первые runbooks для проекта:

1. `RB-001-openrouter-e205.md` — действия при массовых ошибках `E205` (ключ, endpoint, provider-side сбои).
2. `RB-002-db-connection-local.md` — восстановление локального подключения к PostgreSQL.
3. `RB-003-release-smoke-fail.md` — что проверять, если после deploy smoke `/up` или `POST /generation_requests` не проходит.
