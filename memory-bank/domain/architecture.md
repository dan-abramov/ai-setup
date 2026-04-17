---
title: Architecture Patterns (Task Generator)
doc_kind: domain
doc_function: canonical
purpose: Каноничное место для архитектурных границ task_generator. Читать при изменениях, затрагивающих модули, интеграцию OpenRouter, обработку ошибок и конфигурацию.
derived_from:
  - ../dna/governance.md
status: active
audience: humans_and_agents
---

# Architecture Patterns

Этот документ фиксирует текущие архитектурные границы Rails-приложения `task_generator` и правила, которые должны сохраняться при доработках.

## Module Boundaries

| Context | Owns | Must not depend on directly |
| --- | --- | --- |
| `web` (`app/controllers`, `app/views`, Stimulus controller) | HTTP-контракты, рендеринг страниц, клиентские state-переходы `EMPTY/LOADING/SUCCESS/ERROR` | `Net::HTTP` и детали OpenRouter-запроса |
| `request_orchestration` (`GenerationRequests::SubmitService`) | use-case `submit -> generation -> task creation`, итоговый verdict для контроллера | прямые SQL/`update_columns` в обход generation-сервиса |
| `generation_core` (`Generation::BuildDescriptionService`, `Generation::DescriptionValidator`) | lifecycle `GenerationRequest`, нормализация описания и маппинг ошибок ввода (`E201-E203`), с reserved-контрактом `E206-E209` | детали UI/роутинга |
| `provider_adapter` (`Generation::AiClient`) | интеграция с OpenRouter, retry по fallback-модели, маппинг сетевых ошибок в `E204/E205` | web-слой и ActiveRecord-модели |
| `persistence_and_reporting` (`GenerationRequest`, `Task`, `GenerationFlowController#metrics`) | хранение запросов/задач, метрики `p95` и `success_rate` | генерация текста через внешнего провайдера |

Базовые правила:

- контроллеры только оркестрируют use-case и формируют HTTP-ответ, доменная логика живет в service objects;
- публичный контракт API и UI основан на стабильных `status` и `error_code`, а не на текстах исключений;
- единственная точка интеграции с OpenRouter находится в `Generation::AiClient`.

## Concurrency And Critical Sections

Сейчас генерация выполняется синхронно в рамках одного HTTP-запроса, без фоновых job и без отдельного locking-механизма.

Текущий canonical pattern:

1. Провалидировать вход (`GenerationRequest.new(...).valid?`).
2. Создать запись `generation_requests` в `LOADING`.
3. Выполнить AI-вызов и доменную валидацию.
4. Обновить `generation_requests` до `SUCCESS` или `ERROR`.
5. При успехе создать `Task`.

Правила расширения:

- если добавляется асинхронный режим (job queue), нужна идемпотентность по `generation_request_id` и запрет на повторную генерацию при reopen `/task/:id`;
- запрещено добавлять параллельные AI-вызовы для одного запроса без явного ADR и обновления error-contract.

## Failure Handling And Error Tracking

Единый подход к отказам:

- `GenerationRequest` отвечает за input-ошибки (`E201-E203`);
- `Generation::AiClient` отвечает за provider/timeouts (`E204/E205`);
- `Generation::BuildDescriptionService` переводит исключения в доменный verdict (`E205`) и фиксирует статус/latency;
- `Generation::DescriptionValidator` сейчас выполняет нормализацию и держит reserved error-contract (`E206-E209`) для последующего ужесточения валидации;
- `GenerationRequests::SubmitService` отвечает за `Task`-уровень (`E301`);
- `TasksController` отвечает за read-path ошибки (`E302/E303`).

Практическое правило: наружу отдаем только `state/error_code`, а исключения остаются внутренней диагностикой (логирование в `BuildDescriptionService`).

## Configuration Ownership

Owner-слой конфигурации генерации:

- canonical owner: `task_generator/config/initializers/generation.rb`;
- загрузка env: `../.env`, `../.env.local`, `task_generator/.env`, `task_generator/.env.local`;
- обязательные параметры: `OPENROUTER_API_KEY`, `OPENROUTER_TIMEOUT_SECONDS`;
- параметр `OPENROUTER_API_URL` имеет default;
- модели primary/fallback задаются в initializer, а не в контроллерах/сервисах верхнего уровня.

При изменении env-контракта:

1. Обновить `config/initializers/generation.rb`.
2. Обновить документацию в [`../ops/config.md`](../ops/config.md) и `task_generator/README.md`.
3. Уточнить тесты на соответствующие `error_code` и fallback-поведение.
