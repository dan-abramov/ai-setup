# Task Generator

Rails 7.1 приложение для генерации короткого описания задачи по `skill/topic` перед переходом к шагу решения.

## Пользовательский сценарий

1. Пользователь открывает форму `/generation_requests/new`.
2. Отправляет `skill` и `topic`.
3. Система выполняет flow: `submit -> generation -> validate -> persist`.
4. При `SUCCESS` пользователь видит `task_description` и кнопку перехода к `/generation_flow/:id`.
5. При `ERROR` пользователь получает код ошибки. Для `E204-E209` доступно действие `Повторить`.

## Контракт `POST /generation_requests`

### Успех

- HTTP `200`
- JSON:

```json
{
  "state": "SUCCESS",
  "generation_request_id": 123,
  "task_description": "Warhammer 40K: выстрой строй. Реши через сортировка"
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

Для `E201-E203` поле `generation_request_id` не возвращается и запись в `generation_requests` не создаётся.

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

## Переход к решению

`GET /generation_flow/:id` доступен только когда у `GenerationRequest`:

- `status = SUCCESS`
- `task_description` непустой

Иначе выполняется redirect на форму с сообщением об ошибке.

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
