---
title: Stages And Non-Local Environments
doc_kind: engineering
doc_function: canonical
purpose: Текущее состояние non-local окружений и правила безопасного доступа для task_generator.
derived_from:
  - ../dna/governance.md
status: active
audience: humans_and_agents
---

# Stages And Non-Local Environments

На момент адаптации в репозитории зафиксировано только локальное окружение. Канонических `staging`/`production` entrypoints в кодовой базе пока нет.

## Environment Inventory

| Environment | Purpose | Access path | Notes |
| --- | --- | --- | --- |
| `local` | Разработка и тесты | `cd task_generator` + `bin/rails s` | Единственное canonical окружение в репозитории |
| `staging` | Не настроено | N/A | Добавить в документ до первого использования |
| `production` | Не настроено | N/A | Любые действия только после явного согласования |

## Common Operations

Ниже только реально доступные и безопасные операции для текущего состояния:

```bash
cd task_generator
bin/rails s
bundle exec rspec
bin/rails db:prepare
curl -fsS http://localhost:3000/up
```

Правила для операций:

- запускать может разработчик/агент в рамках локальной среды;
- mutating операции с БД (`db:drop`, `db:migrate`) допускаются только локально;
- любые non-local операции (если появятся) требуют отдельного approval и описания в этом документе.

## Credentials And Access

Текущее правило доступа:

- локально переменные задаются через shell/env и `.env`/`.env.local`;
- инициализатор подхватывает только `OPENROUTER_*`;
- реальные production credentials не хранятся в `memory-bank` и не должны попадать в git.

Недопустимый обход:

- хранить live-ключи в документации;
- запускать live-операции из непроверенных скриптов;
- выполнять действия в неописанном non-local окружении.

## Version And Health Checks

Безопасные проверки, которые доступны сейчас:

- версия текущего кода: `git rev-parse --short HEAD`;
- health endpoint: `curl -fsS http://localhost:3000/up`;
- smoke URL: `http://localhost:3000/`.

## Logs And Observability

Canonical источники наблюдаемости:

- локальные Rails-логи: `task_generator/log/development.log` или STDOUT процесса `bin/rails s`;
- тестовые логи: вывод `bundle exec rspec`;
- продуктовые метрики генерации: `GET /generation_flow/metrics`.

Централизованные traces/error tracker/dashboards для non-local окружений пока не зафиксированы.

## Test Data And Smoke Targets

Для локальных smoke-проверок используй:

- ручной ввод `skill/topic` через `/generation_requests/new`;
- тестовые данные из FactoryBot в `spec/factories`;
- при необходимости локальные seed-данные из `db/seeds.rb`.

Staging/demo tenants и shared test accounts пока не определены.

## Adoption Checklist

- [x] перечислены все известные окружения (включая отсутствие non-local)
- [x] указаны canonical access paths
- [x] описаны safe health/version checks
- [x] перечислены observability entrypoints
- [x] удалены фальшивые или нерелевантные примеры
