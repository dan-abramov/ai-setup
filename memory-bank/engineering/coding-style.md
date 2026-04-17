---
title: Coding Style
doc_kind: engineering
doc_function: convention
purpose: Соглашения по стилю кода и tooling для проекта task_generator.
derived_from:
  - ../dna/governance.md
status: active
audience: humans_and_agents
---

# Coding Style

## General Rules

- Следуй Rails-конвенциям: `snake_case` для файлов и методов, `CamelCase` для классов/модулей.
- Поддерживай границы MVC: контроллеры оркестрируют request/response, бизнес-логика живет в моделях и `app/services`.
- Для orchestration-сценариев используй service objects в `app/services/<context>/`.
- Публичный интерфейс service object — `.call` и явный result-объект (`Data.define` или эквивалент с `success?`/`error?`).
- User-facing error codes (`E201`…`E303`) хранятся в коде как явные константы/правила, а не магические строки по месту.
- Комментарии добавляй только для объяснения `why`, boundary conditions и нетривиальных trade-offs.

## Tooling Contract

Canonical локальные команды:

- `bundle exec rspec`
- `bundle exec rspec spec/models spec/services`
- `bundle exec rspec spec/requests spec/system`
- `bin/rails s` (локальный запуск приложения)

Дополнительно:

- Отдельный formatter/linter (например RuboCop) пока не зафиксирован как canonical.
- Новые гемы и tooling нельзя добавлять без согласования с пользователем.

## Language-Specific Addendum

### Backend (Ruby on Rails)

- В контроллере не размещай бизнес-логику, которая может быть протестирована отдельно как service/model contract.
- Внешние HTTP-вызовы держи в изолированном adapter/service (пример: `Generation::AiClient`).
- При изменении контракта endpoint одновременно обновляй соответствующие request specs.

### Frontend (ERB + Stimulus)

- UI-логика ограничивается Stimulus-контроллерами в `app/javascript/controllers`.
- Бизнес-решения не должны прятаться во фронтенд-скриптах: source of truth остается на серверной стороне.

### SQL / migrations

- Миграции должны быть обратимыми (`change` или явные `up/down`).
- Не редактируй `schema.rb` вручную.
- Изменения БД должны сопровождаться тестами на затронутые model/service/request контракты.

## Change Discipline

- Не переписывай несвязанный код только ради единообразия, если задача этого не требует.
- При touch-up изменениях следуй существующему локальному стилю файла, если нет явного конфликта с canonical rule.
- Если встречается конфликт между общим правилом и фактическим стилем файла, зафиксируй решение в PR/документации, а не оставляй на догадки.
