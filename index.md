# Project Index (ai-setup / task_generator)

Этот файл — root routing для проекта. Его задача: быстро направить в правильный слой документации или кода, не читая репозиторий целиком.

## Reading Order

1. [PROJECT.md](PROJECT.md)
2. [AGENTS.md](AGENTS.md)
3. [PRD.md](PRD.md)
4. [memory-bank/README.md](memory-bank/README.md)
5. [.prompts/README.md](.prompts/README.md)
6. [task_generator/README.md](task_generator/README.md)
7. [memory-bank/features/README.md](memory-bank/features/README.md)

## Project Context


| Файл                                                 | Что это                                                      | Читать, когда нужно                                         |
| ---------------------------------------------------- | ------------------------------------------------------------ | ----------------------------------------------------------- |
| [PROJECT.md](PROJECT.md)                             | Продуктовая рамка и цель проекта                             | Восстановить смысл продукта до работы с деталями реализации |
| [PRD.md](PRD.md)                                     | Product Requirements на уровне инициативы MVP                | Проверить scope/goal до перехода к feature-спеке            |
| [task_generator/README.md](task_generator/README.md) | Публичный контракт приложения: flow, endpoint-ы, error codes | Проверить текущее ожидаемое поведение API/UI                |
| [AGENTS.md](AGENTS.md)                               | Routing-таблица, правила и ограничения работы агента         | Понять границы автономии и вход в нужный слой документации  |


## Memory Bank (Canonical Docs)


| Файл                                                                                           | Что это                                                    | Читать, когда нужно                                 |
| ---------------------------------------------------------------------------------------------- | ---------------------------------------------------------- | --------------------------------------------------- |
| [memory-bank/README.md](memory-bank/README.md)                                                 | Главный индекс memory-bank                                 | Найти нужный слой документации                      |
| [memory-bank/prd/PRD-001-task-generator-mvp.md](memory-bank/prd/PRD-001-task-generator-mvp.md) | Initiative-level PRD для MVP генерации задач               | Сверить цели/scope перед работой с конкретной фичей |
| [memory-bank/dna/README.md](memory-bank/dna/README.md)                                         | Правила SSoT, frontmatter, lifecycle                       | Проверить, где canonical owner факта                |
| [memory-bank/domain/problem.md](memory-bank/domain/problem.md)                                 | Каноничное описание продукта и верхнеуровневых ограничений | Начать новую фичу без дублирования product context  |
| [memory-bank/domain/architecture.md](memory-bank/domain/architecture.md)                       | Архитектурные границы модулей и обработка ошибок           | Менять сервисы/контракты, не ломая границы слоев    |
| [memory-bank/domain/frontend.md](memory-bank/domain/frontend.md)                               | UI-поверхности и правила взаимодействия SSR + Stimulus     | Трогать form flow, state machine, i18n              |
| [memory-bank/engineering/testing-policy.md](memory-bank/engineering/testing-policy.md)         | Правила достаточного покрытия и verify                     | Понять, какие тесты обязательны для change surface  |
| [memory-bank/engineering/coding-style.md](memory-bank/engineering/coding-style.md)             | Конвенции кода Rails + services                            | Держать стиль изменений единообразным               |
| [memory-bank/ops/config.md](memory-bank/ops/config.md)                                         | Runtime/env contracts                                      | Менять или проверять конфигурацию OPENROUTER/RAILS  |
| [memory-bank/flows/feature-flow.md](memory-bank/flows/feature-flow.md)                         | Lifecycle фич и ID taxonomy (`REQ-*`, `CHK-*`, `EVID-*`)   | Вести фичу по стадиям от draft до done              |
| [memory-bank/features/README.md](memory-bank/features/README.md)                               | Реестр feature packages                                    | Найти текущие фичи FT-001..FT-003                   |


## Feature Packages


| Файл                                                                             | Что это                                            | Читать, когда нужно                        |
| -------------------------------------------------------------------------------- | -------------------------------------------------- | ------------------------------------------ |
| [memory-bank/features/FT-001/feature.md](memory-bank/features/FT-001/feature.md) | Ввод `skill/topic` и ошибки валидации входа        | Работать с входным шагом формы             |
| [memory-bank/features/FT-002/feature.md](memory-bank/features/FT-002/feature.md) | Генерация `task_description`, `E201-E209`, metrics | Менять generation pipeline и state machine |
| [memory-bank/features/FT-003/feature.md](memory-bank/features/FT-003/feature.md) | Создание `Task` и reopen через `/task/:id`         | Менять reopen flow и ошибки `E301-E303`    |


## Code Map (`task_generator/`)


| Путь                                                                                                                                                               | Что владеет                                                                  | Читать, когда нужно                               |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------- | ------------------------------------------------- |
| [task_generator/config/routes.rb](task_generator/config/routes.rb)                                                                                                 | HTTP entrypoints (`/generation_requests`, `/task/:id`, `/generation_flow/*`) | Проверить маршруты и связанный controller flow    |
| [task_generator/app/controllers/generation_requests_controller.rb](task_generator/app/controllers/generation_requests_controller.rb)                               | JSON-контракт `POST /generation_requests`                                    | Менять payload `SUCCESS/ERROR` и коды ответа      |
| [task_generator/app/controllers/tasks_controller.rb](task_generator/app/controllers/tasks_controller.rb)                                                           | Reopen контракт `GET /task/:id` и `E302/E303`                                | Менять поведение открытия сохраненной задачи      |
| [task_generator/app/controllers/generation_flow_controller.rb](task_generator/app/controllers/generation_flow_controller.rb)                                       | Guard `generation_flow/:id` и метрики окна 200 запросов                      | Менять расчеты `p95/success_rate` и fallback flow |
| [task_generator/app/services/generation_requests/submit_service.rb](task_generator/app/services/generation_requests/submit_service.rb)                             | Оркестрация submit и создание `Task`, ошибка `E301`                          | Менять верхнеуровневый use-case submit            |
| [task_generator/app/services/generation/build_description_service.rb](task_generator/app/services/generation/build_description_service.rb)                         | Pipeline `validate input -> AI call -> validate output -> persist`           | Менять статусную модель `GenerationRequest`       |
| [task_generator/app/services/generation/ai_client.rb](task_generator/app/services/generation/ai_client.rb)                                                         | OpenRouter client, timeout/provider errors (`E204/E205`)                     | Менять интеграцию с внешним AI                    |
| [task_generator/app/services/generation/description_validator.rb](task_generator/app/services/generation/description_validator.rb)                                 | Пост-валидация описания (`E206-E209`)                                        | Ужесточать/менять правила valid description       |
| [task_generator/app/models/generation_request.rb](task_generator/app/models/generation_request.rb)                                                                 | Нормализация `skill/topic`, input errors (`E201-E203`)                       | Менять доменный контракт входных данных           |
| [task_generator/app/models/task.rb](task_generator/app/models/task.rb)                                                                                             | Контракт хранения итогового описания задачи                                  | Менять ограничения `tasks.description`            |
| [task_generator/app/javascript/controllers/generation_request_form_controller.js](task_generator/app/javascript/controllers/generation_request_form_controller.js) | Клиентская state machine и retry rules                                       | Менять UX отправки формы и redirect               |
| [task_generator/config/initializers/generation.rb](task_generator/config/initializers/generation.rb)                                                               | Canonical owner `OPENROUTER_*`, timeout, primary/fallback model              | Проверять и менять runtime-конфигурацию генерации |
| [task_generator/db/schema.rb](task_generator/db/schema.rb)                                                                                                         | Актуальная схема БД (`generation_requests`, `tasks`)                         | Проверить текущую модель данных                   |


## Test Map


| Путь                                                                                                                         | Что проверяет                                   | Читать, когда нужно                   |
| ---------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------- | ------------------------------------- |
| [task_generator/spec/requests/generation_requests_spec.rb](task_generator/spec/requests/generation_requests_spec.rb)         | Контракт `POST /generation_requests`            | Проверить API-совместимость изменений |
| [task_generator/spec/requests/tasks_spec.rb](task_generator/spec/requests/tasks_spec.rb)                                     | Контракт `GET /task/:id`                        | Проверить reopen и ошибки `E302/E303` |
| [task_generator/spec/requests/generation_flow_spec.rb](task_generator/spec/requests/generation_flow_spec.rb)                 | Контракт `GET /generation_flow/metrics` и guard | Проверить метрики и доступность flow  |
| [task_generator/spec/services/generation/**/*.rb](task_generator/spec/services/generation/build_description_service_spec.rb) | Логика generation core и adapter layer          | Проверить поведение сервисного слоя   |
| [task_generator/spec/system/generation_request_flow_spec.rb](task_generator/spec/system/generation_request_flow_spec.rb)     | Сквозной пользовательский сценарий формы        | Проверить UI flow end-to-end          |


## Canonical Ownership Notes

- По runtime-конфигурации (`OPENROUTER_`*, timeout, модели) source of truth: [task_generator/config/initializers/generation.rb](task_generator/config/initializers/generation.rb).
- По продуктовым и архитектурным фактам source of truth: `memory-bank/domain/*`.
- По lifecycle фич source of truth: `memory-bank/features/FT-*/feature.md` + `memory-bank/flows/feature-flow.md`.

## Legacy Artifacts

- Каталог `.memory_bank/features/*` содержит исторические артефакты HW-1.
- Для новых сессий и изменений используй `memory-bank/` как основной контур документации.

## Prompt Pack

- `.prompts/orient.md` — быстрый вход и triage контекста.
- `.prompts/spec.md` — подготовка/обновление feature-спеки.
- `.prompts/implement.md` — реализация по `feature.md` + `implementation-plan.md`.
- `.prompts/review.md` — review по traceability и рискам.
- `.prompts/resume.md` — resume/continue без полного повторного чтения.

## Common Commands

```bash
cd task_generator
bin/rails db:prepare
bin/rails s
bundle exec rspec
bundle exec rspec spec/models spec/services
bundle exec rspec spec/requests spec/system
```
