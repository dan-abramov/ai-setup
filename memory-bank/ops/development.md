---
title: Development Environment
doc_kind: engineering
doc_function: canonical
purpose: Canonical правила локальной разработки для Rails-приложения task_generator внутри ai-setup.
derived_from:
  - ../dna/governance.md
status: active
audience: humans_and_agents
---

# Development Environment

Основная рабочая директория приложения: `task_generator/`.

## Setup

Минимальная подготовка среды состоит из двух частей: bootstrap репозитория и setup Rails-приложения.

```bash
# Из корня репозитория ai-setup
make bootstrap
direnv allow

# Дальше внутри приложения
cd task_generator
bundle install
bin/rails db:prepare
```

Альтернативный идемпотентный setup внутри приложения:

```bash
cd task_generator
bin/setup
```

## Daily Commands

Canonical ежедневные команды для `task_generator`:

```bash
cd task_generator
bin/rails s
bundle exec rspec
bundle exec rspec spec/models spec/services
bundle exec rspec spec/requests spec/system
bin/rails db:prepare
```

Дополнительно по необходимости:

```bash
cd task_generator
bin/rails console
bin/rails db:drop db:create db:migrate
```

## Browser Testing

UI есть, canonical локальный URL: `http://localhost:3000`.

Правила:

1. Запускай сервер командой `bin/rails s` из `task_generator/`.
2. Если нужен нестандартный порт, задавай его явно: `PORT=3001 bin/rails s`.
3. Без явного запроса не сканируй порты вручную.
4. Базовые smoke-проверки:
   - `GET /` открывает форму генерации;
   - `GET /up` возвращает health-ответ;
   - `POST /generation_requests` корректно отдает `SUCCESS` или `ERROR`.

## Database And Services

Для локальной работы критичны:

- PostgreSQL (обязателен для `db:prepare`, app и тестов).
- Миграции и подготовка БД: `bin/rails db:prepare`.
- Полный reset БД: `bin/rails db:drop db:create db:migrate`.
- Seeds: `db/seeds.rb` существует, но обязательных seed-данных для базового сценария нет.
- Внешний AI-провайдер нужен только для живой генерации; automated tests должны мокать/стабать сетевые вызовы.

Known pitfalls:

- Если `OPENROUTER_API_KEY` пустой или невалидный, генерация возвращает `E205`.
- `OPENROUTER_TIMEOUT_SECONDS` по умолчанию равен `15`; если значение слишком низкое, при медленном ответе возможен `E204`.
- Инициализатор загружает только `OPENROUTER_*` из файлов в порядке:
  1. `../.env`
  2. `../.env.local`
  3. `.env`
  4. `.env.local`

## Adoption Checklist

- [x] указаны реальные setup-команды
- [x] указаны реальные test-команды
- [x] документирован способ определения локального URL
- [x] перечислены локальные зависимости и сервисы
- [x] удалены нерелевантные примеры
