---
title: Release And Deployment
doc_kind: engineering
doc_function: canonical
purpose: Текущий релизный процесс для task_generator в ai-setup, включая release-gates и rollback-подход.
derived_from:
  - ../dna/governance.md
status: active
audience: humans_and_agents
---

# Release And Deployment

## Release Flow

В проекте пока нет полностью автоматизированного deployment pipeline. Canonical release unit сейчас: merged commit в `main` + подтвержденные локальные проверки.

Текущий порядок шагов:

1. Сделать изменения в feature-ветке.
2. Запустить обязательные проверки для затронутой части:
   - изменения `task_generator`: `bundle exec rspec` (из `task_generator/`);
   - docs/bootstrap-изменения: соответствующие checks (`make check`, `make check-context`) по необходимости.
3. Создать PR с описанием проверки и ограничений.
4. После review и зеленых CI-джоб (`lint`, `smoke-bootstrap`) смержить в `main`.
5. Если есть внешняя деплой-среда, ответственный человек выполняет ручной deploy вне этого репозитория.
6. Выполнить post-deploy smoke (`/up`, основной пользовательский поток генерации).

## Release Commands

Canonical команды для release-проверок:

```bash
# Из корня ai-setup
make check
make check-context

# Из task_generator
bundle exec rspec
RAILS_ENV=production SECRET_KEY_BASE_DUMMY=1 bin/rails assets:precompile
docker build -t task_generator:local .
```

Текущие правила:

- для runtime-сценария генерации обязательны `OPENROUTER_API_KEY` и `OPENROUTER_TIMEOUT_SECONDS`;
- любые non-local deploy шаги требуют явного approval и выполняются вручную;
- automated часть сейчас ограничена CI и локальными проверками, deploy manual.

## Release Test Plan

При каждом релизе полезно создавать отдельный тестовый план.

**Формат:** `release-v{VERSION}-test-plan.md`

**Минимальная структура:**

```markdown
# Тестовый план релиза v{VERSION}

**Дата:** YYYY-MM-DD
**Предыдущая версия:** v{PREV_VERSION}
**Текущая версия:** v{VERSION}
**Стенд:** <environment>

## Обзор изменений

| Issue | Название | Тип | Приоритет |
| --- | --- | --- | --- |
| #XXXX | Описание задачи | Feature/Fix/Refactoring/Tech debt | Высокий/Средний/Низкий |

## Проверка изменений

- [ ] Описан хотя бы один test case для каждого крупного change set

## Smoke-тесты

- [ ] `GET /` открывает форму генерации
- [ ] `POST /generation_requests` корректно отдает `SUCCESS` или `ERROR`
- [ ] `GET /task/:id` открывает ранее созданную задачу
- [ ] `GET /up` отвечает успешно
```

## Rollback

Текущая политика rollback:

- rollback unit: предыдущий стабильный commit или предыдущий Docker image tag;
- fastest safe rollback: откатить runtime на предыдущий артефакт и повторить smoke `/up` + базовый пользовательский поток;
- подтверждение rollback для non-local окружений делает ответственный за runtime владелец;
- необратимые изменения: потенциально destructive миграции БД (перед merge должны иметь отдельный review и rollback-план).
