---
title: Testing Policy
doc_kind: engineering
doc_function: canonical
purpose: Testing policy для Rails-проекта task_generator: обязательность regression coverage, правила test case design и допустимые manual-only исключения.
derived_from:
  - ../dna/governance.md
  - ../flows/feature-flow.md
status: active
canonical_for:
  - repository_testing_policy
  - feature_test_case_inventory_rules
  - automated_test_requirements
  - sufficient_test_coverage_definition
  - manual_only_verification_exceptions
  - simplify_review_discipline
  - verification_context_separation
must_not_define:
  - feature_acceptance_criteria
  - feature_scope
audience: humans_and_agents
---

# Testing Policy

## Project Adaptation

Project-specific testing stack:

- **Framework:** `rspec-rails`
- **Data:** `FactoryBot` (`spec/factories`), transactional fixtures (`config.use_transactional_fixtures = true`)
- **Canonical test directories:** `spec/models`, `spec/services`, `spec/requests`, `spec/system`
- **Local commands:**
  - `bundle exec rspec`
  - `bundle exec rspec spec/models spec/services`
  - `bundle exec rspec spec/requests spec/system`
  - `bin/rails db:prepare RAILS_ENV=test` (при первой настройке или после миграций)
- **CI jobs (текущее состояние):**
  - В корневом `.github/workflows/ci.yml` есть `lint` и `smoke-bootstrap`;
  - Отдельной обязательной CI-джобы с `bundle exec rspec` для `task_generator` пока нет;
  - До добавления такой джобы локальный прогон `bundle exec rspec` обязателен перед handoff/PR.
- **Manual-only исключения:**
  - Проверки, зависящие от нестабильного внешнего AI API (таймауты/сетевые деградации);
  - Визуальная проверка UX-деталей в браузере, если сценарий сложно стабильно автоматизировать.

## Core Rules

- Любое изменение поведения, которое можно проверить детерминированно, обязано получить automated regression coverage.
- Любой новый или измененный contract обязан получить contract-level automated verification.
- Любой bugfix обязан добавить regression test на воспроизводимый сценарий.
- Required automated tests считаются закрывающими риск только если они проходят локально и в CI.
- Manual-only verify допустим только как явное исключение и не заменяет automated coverage там, где automation реалистична.
- Изменения API-контрактов `POST /generation_requests`, `GET /task/:id`, `GET /generation_flow/:id`, `GET /generation_flow/metrics` обязаны сопровождаться request specs.
- Изменения в `app/services/**` обязаны сопровождаться service specs.
- Изменения в model validations/callbacks обязаны сопровождаться model specs.

## Ownership Split

- Canonical test cases delivery-единицы задаются в `feature.md` через `SC-*`, feature-specific `NEG-*`, `CHK-*` и `EVID-*`.
- `implementation-plan.md` владеет только стратегией исполнения: какие test surfaces будут добавлены или обновлены, какие gaps временно остаются manual-only и почему.

## Feature Flow Expectations

Canonical lifecycle gates живут в [../flows/feature-flow.md](../flows/feature-flow.md):

- к `Design Ready` `feature.md` уже фиксирует test case inventory;
- к `Plan Ready` `implementation-plan.md` содержит `Test Strategy` с planned automated coverage и manual-only gaps;
- к `Done` required tests добавлены, локальные команды зелёные и CI не противоречит локальному verify.

## Что Считается Sufficient Coverage

- Покрыт основной changed behavior и ближайший regression path.
- Покрыты новые или измененные contracts, события, schema или integration boundaries.
- Покрыты критичные failure modes из `FM-*`, bug history или acceptance risks.
- Покрыты feature-specific negative/edge scenarios, если они меняют verdict.
- Процент line coverage сам по себе недостаточен: нужен scenario- и contract-level coverage.
- Для ошибок `E201`…`E209`, `E301`…`E303` покрыты затронутые ветки выдачи кода/статуса.

## Когда Manual-Only Допустим

- Сценарий зависит от live infra, внешних систем, hardware, недетерминированной среды или human оценки UI.
- Для каждого manual-only gap: причина, ручная процедура, owner follow-up.
- Если manual-only gap оставляет без regression protection критичный путь, feature не считается завершённой.
- Для integration с OpenRouter manual-only проверка не заменяет unit/request тесты на обработку ответов и ошибок (включая fallback/timeout ветки).

## Simplify Review

Отдельный проход верификации после функционального тестирования. Цель: убедиться, что реализация минимально сложна.

- Выполняется после прохождения tests, но до closure gate.
- Паттерны: premature abstractions, глубокая вложенность, дублирование логики, dead code, overengineering.
- Три похожие строки лучше premature abstraction. Абстракция оправдана только когда она реально уменьшает риск или повтор.

## Verification Context Separation

Разные этапы верификации — отдельные проходы:

1. **Функциональная верификация** — tests проходят, acceptance scenarios покрыты
2. **Simplify review** — код минимально сложен
3. **Acceptance test** — end-to-end по `SC-*`

Для small features допустимо в одной сессии, но simplify review не пропускается.

## Project-Specific Conventions

- Новые тесты добавляются в существующие каталоги `spec/models`, `spec/services`, `spec/requests`, `spec/system`.
- Для setup используется `rails_helper` + `spec/support/**/*.rb`; FactoryBot подключается через `spec/support/factory_bot.rb`.
- Для данных используй `build/create` фабрики и traits вместо хардкод-создания записей, если это не снижает читаемость кейса.
- В тестах нельзя выполнять реальные сетевые запросы к AI-провайдеру: используй `class_double`, `allow(...).to receive`, либо инъекцию тестового клиента.
- Для bugfix обязателен тест на сломанный до фикса сценарий с явной проверкой ожидаемого результата.
- Перед handoff агент обязан запустить как минимум `bundle exec rspec` в `task_generator` или явно зафиксировать, почему это не удалось.

## Checklist For Template Adoption

- [x] указаны реальные local test commands
- [x] перечислены обязательные CI suites и текущие gaps
- [x] задокументирован deterministic test data pattern
- [x] описаны manual-only exceptions
- [x] policy не противоречит [../flows/feature-flow.md](../flows/feature-flow.md)
