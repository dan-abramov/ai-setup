# Task Generator

Rails 7.1 приложение для генерации и повторного открытия короткой задачи по `skill/topic`.

## Пользовательский сценарий

1. Пользователь открывает форму `/generation_requests/new`.
2. Отправляет `skill` и `topic`.
3. Система выполняет flow: `submit -> generation -> validate -> create Task`.
4. При `SUCCESS` фронтенд сразу делает redirect на `/task/:id`.
5. При `ERROR` пользователь получает код ошибки. Для `E204-E209` и `E301` доступно действие `Повторить`.
6. После закрытия вкладки задачу можно открыть повторно по URL `/task/:id`.

## Контракт `POST /generation_requests`

### Успех

- HTTP `200`
- JSON:

```json
{
  "state": "SUCCESS",
  "task_id": 123,
  "task_path": "/task/123"
}
```

### Ошибка

- HTTP `422`
- JSON:

```json
{
  "state": "ERROR",
  "error_code": "E204",
  "generation_request_id": 123
}
```

Правила:

- Для `E201-E203` поле `generation_request_id` не возвращается и запись в `generation_requests` не создаётся.
- Для `E204-E209` и `E301` поле `generation_request_id` возвращается.
- Для `E201-E209` и `E301` запись в `tasks` не создаётся.

## Контракт `GET /task/:id`

- HTTP `200`: задача открыта, отображается `tasks.description`.
- HTTP `404`: ошибка `E302` (`Задача не найдена`).
- HTTP `422`: ошибка `E303` (`Задача недоступна для открытия`).

`GET /task/:id` не запускает повторную генерацию.

## Контракт `task_description` (valid description)

После `strip_tags + trim` описание должно:

- быть непустым;
- иметь длину `<= 150`;
- содержать `topic` (case-insensitive);
- содержать `skill` (case-insensitive);
- содержать фразу `Реши через`.

## Коды ошибок

- `E201`: `skill` пустой после нормализации.
- `E202`: `topic` пустой после нормализации.
- `E203`: `skill` или `topic` длиннее 100.
- `E204`: таймаут генерации.
- `E205`: ошибка провайдера, конфигурации или внутренняя ошибка генерации.
- `E206`: результат генерации пустой.
- `E207`: результат длиннее 150 символов.
- `E208`: в результате отсутствует `topic`.
- `E209`: в результате отсутствует `skill` или фраза `Реши через`.
- `E301`: не удалось сохранить `Task`.
- `E302`: `Task` не найден при открытии `/task/:id`.
- `E303`: `Task` найден, но `description.blank?`.

## OpenRouter configuration

Обязательные переменные:

- `OPENROUTER_API_KEY`
- `OPENROUTER_TIMEOUT_SECONDS`

Дополнительно (необязательно):

- `OPENROUTER_API_URL` (по умолчанию `https://openrouter.ai/api/v1/chat/completions`)

Переменные можно задать через окружение или в файлах:

- `../.env` / `../.env.local` (корень репозитория `ai-setup`)
- `.env` / `.env.local` (внутри `task_generator`)

Если `OPENROUTER_API_KEY` пустой, генерация возвращает `E205`.

Используемые модели:

- Primary: `qwen/qwen2.5-7b-instruct:free`
- Fallback: `meta-llama/llama-3.1-8b-instruct:free`

## Повторное открытие задачи

Сценарий:

1. Получить `task_path` из успешного ответа `POST /generation_requests`.
2. Открыть URL `/task/:id`.
3. После закрытия вкладки снова открыть тот же URL.

Ожидаемое поведение: задача открывается без нового запроса к AI.

## Метрики AC-08

Endpoint: `GET /generation_flow/metrics`

Возвращает JSON с метриками на окне последних 200 валидных запросов (`SUCCESS`/`ERROR` с `latency_ms`):

- `p95_latency_ms`
- `success_rate`
- `thresholds`
- `meets_slo`

Целевые пороги:

- `p95 <= 1000ms`
- `success_rate >= 95%`

## Требования

- Ruby `3.4.8`
- PostgreSQL
- Bundler

## Запуск

```bash
bundle install
bin/rails db:prepare
bin/rails s
```

## Тесты

```bash
bundle exec rspec
```

Выборочный прогон:

```bash
bundle exec rspec spec/models spec/services
bundle exec rspec spec/requests spec/system
```
