---
title: Configuration Guide
doc_kind: engineering
doc_function: canonical
purpose: Canonical описание конфигурации task_generator: env contract, owners и правила работы с секретами.
derived_from:
  - ../dna/governance.md
status: active
audience: humans_and_agents
---

# Configuration Guide

Документ фиксирует реальную модель конфигурации `task_generator` и ключевые runtime contracts.

## Configuration Architecture

Проект использует комбинацию Rails-конфигов и env vars:

- базовые настройки Rails: `config/application.rb`, `config/environments/*.rb`;
- БД: `config/database.yml` (+ опциональный `DATABASE_URL`);
- runtime-настройки генерации: `config/initializers/generation.rb`;
- секреты и переменные окружения: shell env + `.env/.env.local`.

### File Layout

```text
task_generator/config/
├── application.rb
├── database.yml
├── environments/
│   ├── development.rb
│   ├── test.rb
│   └── production.rb
└── initializers/
    └── generation.rb
```

### Ownership Rules

Правила ownership:

1. `config/initializers/generation.rb` владеет схемой `OPENROUTER_*` и `config.x.generation`.
2. Defaults для OpenRouter задаются там же:
   - `OPENROUTER_API_URL` default: `https://openrouter.ai/api/v1/chat/completions`
   - `OPENROUTER_TIMEOUT_SECONDS` default: `1`
3. Environment-specific overrides задаются через обычные env vars и `config/environments/*.rb`.
4. Секреты документируются только по именам переменных, без значений.

```ruby
# Реальный API доступа:
Rails.application.config.x.generation.openrouter_api_url
Rails.application.config.x.generation.openrouter_api_key
Rails.application.config.x.generation.openrouter_timeout_seconds
ENV.fetch("PORT", "3000")
```

## Naming Convention For Env Vars

| Config area | Env variable |
| --- | --- |
| OpenRouter API key | `OPENROUTER_API_KEY` |
| OpenRouter API URL | `OPENROUTER_API_URL` |
| OpenRouter timeout | `OPENROUTER_TIMEOUT_SECONDS` |
| Rails thread pool | `RAILS_MAX_THREADS` |
| Rails log level | `RAILS_LOG_LEVEL` |
| Database URL override | `DATABASE_URL` |
| Production DB password | `TASK_GENERATOR_DATABASE_PASSWORD` |

Rules:

- для AI-конфига canonical namespace: `OPENROUTER_*`;
- для Rails используются стандартные `RAILS_*` плюс отдельные runtime vars (`DATABASE_URL`, `TASK_GENERATOR_DATABASE_PASSWORD`);
- в `.env` автоматически подхватываются только переменные с префиксом `OPENROUTER_`;
- остальные переменные должны приходить из shell/infra окружения.

## Documenting Important Variables

Если проекту нужен справочник ключевых переменных, не перечисляй все подряд. Сфокусируйся на значимых runtime contracts.

| Variable | Description | Default | Owner |
| --- | --- | --- | --- |
| `OPENROUTER_API_KEY` | Ключ доступа к OpenRouter | none (обязателен для живой генерации) | developer/platform |
| `OPENROUTER_API_URL` | Endpoint chat completions | `https://openrouter.ai/api/v1/chat/completions` | developer/platform |
| `OPENROUTER_TIMEOUT_SECONDS` | Таймаут HTTP-запроса к AI | `1` | developer/platform |
| `RAILS_MAX_THREADS` | Размер thread pool ActiveRecord | `5` | platform |
| `DATABASE_URL` | Полный URL подключения к БД (override) | none | platform |
| `TASK_GENERATOR_DATABASE_PASSWORD` | Пароль prod-роли в `database.yml` | none | platform |
| `RAILS_LOG_LEVEL` | Уровень логирования production | `info` | platform |

## Secrets

- Никогда не вставляй реальные значения секретов в репозиторий.
- Документируй только способ их хранения, выдачи и rotation policy.
- Для локальной разработки используй `.env.local`/shell env и не публикуй значения в PR/документации.
- Для non-local окружений секреты должны храниться в secret manager платформы (не в git).

## Adoption Checklist

- [x] описан schema-owner конфигурации
- [x] задокументирована naming convention
- [x] перечислены ключевые runtime/env contracts
- [x] описан secret handling
- [x] удалены ссылки на несуществующие downstream-справочники
