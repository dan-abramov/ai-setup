---
title: Frontend (Task Generator)
doc_kind: domain
doc_function: canonical
purpose: Каноничное описание UI-поверхностей, взаимодействий и i18n-слоя task_generator. Читать при изменениях web-интерфейса.
derived_from:
  - ../dna/governance.md
status: active
audience: humans_and_agents
---

# Frontend

Отдельного SPA/mobile frontend в проекте нет. UI реализован как server-rendered Rails views с небольшой интерактивностью через Stimulus.

## UI Surfaces

Текущие поверхности:

- `GET /generation_requests/new`: форма ввода `skill/topic`, статус процесса и retry-кнопка.
- `GET /task/:id`: просмотр созданной задачи или отображение ошибок `E302/E303`.
- `GET /generation_flow/:id`: служебный экран успешной генерации с данными запроса.

Технический слой:

- шаблоны: `task_generator/app/views/**/*`;
- клиентская интерактивность: `task_generator/app/javascript/controllers/generation_request_form_controller.js`;
- стили: `task_generator/app/assets/stylesheets/application.css`.

## Component And Styling Rules

Правила для текущего масштаба проекта:

- единой внешней design system нет; визуальные токены хранятся в CSS custom properties в `application.css`;
- новые состояния формы добавляются через существующий state-механизм Stimulus, а не через ad-hoc inline JS;
- ошибки показываются через i18n ключи и `error_code`, UI не должен хардкодить пользовательские тексты в JS;
- для крупных UI-изменений (новый поток, новый клиентский стейт-машин) сначала фиксируем решение в ADR/feature docs.

## Interaction Patterns

Canonical interactive pattern:

- форма рендерится на сервере (`form_with`) и перехватывается Stimulus-контроллером;
- отправка идет через `fetch` на `POST /generation_requests` с JSON-ответом;
- `SUCCESS` ведет к `window.location.assign(task_path)`;
- `ERROR` показывает код и retry для `E204-E209`, `E301`;
- `GET /task/:id` всегда read-only, без повторной генерации.

Запрещено смешивать конкурирующие паттерны (например, параллельно Turbo Stream и отдельный API-клиент) без явного архитектурного обоснования.

## Localization

Локализация:

- default locale: `:ru` (`task_generator/config/application.rb`);
- источники переводов: `task_generator/config/locales/ru.yml` и `task_generator/config/locales/en.yml`;
- серверные шаблоны используют `t(...)`, а JS получает словари ошибок/статусов через `data-*` атрибуты из ERB;
- при добавлении нового `error_code` нужно обновить оба locale-файла и убедиться, что ключ доступен Stimulus-контроллеру.
