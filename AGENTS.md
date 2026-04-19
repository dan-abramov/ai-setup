Отвечай по-русски, если пользователь пишет по-русски.

Смотри `PROJECT.md` с описанием проекта.

## Быстрый routing (читать в таком порядке)
1. `index.md`
2. `PROJECT.md`
3. `PRD.md`
4. `memory-bank/README.md`
5. `memory-bank/features/README.md`
6. `task_generator/README.md`

## Routing по flow
| Flow | Сначала | Затем | Результат |
| --- | --- | --- | --- |
| Orient / Triage | `index.md`, `PROJECT.md`, `memory-bank/domain/problem.md` | `memory-bank/domain/architecture.md`, `memory-bank/domain/frontend.md` | Быстрое восстановление продуктового и архитектурного контекста |
| Spec | `PRD.md`, `memory-bank/prd/PRD-001-task-generator-mvp.md` | `memory-bank/features/FT-*/feature.md` | Границы scope, требования и критерии на уровне фичи |
| Plan / Implement | `memory-bank/features/FT-*/feature.md` | `memory-bank/features/FT-*/implementation-plan.md`, `memory-bank/engineering/*`, `task_generator/README.md` | Пошаговая реализация без ухода за границы контракта |
| Review / Verify | `memory-bank/features/FT-*/feature.md` (раздел Verify) | diff + `task_generator/spec/**/*` + `memory-bank/engineering/testing-policy.md` | Проверка traceability и регрессий |
| Resume / Continue | `memory-bank/features/README.md` | `memory-bank/features/FT-*/README.md`, `.prompts/resume.md` | Быстрый перезапуск работы без повторного полного чтения |

## Стек
- Ruby on Rails 7
- RSpec
- FactoryBot
- PostgreSQL

## Ключевые команды
- `rails new` — создать новый проект
- `bin/rails s` — запустить сервер
- `bundle exec rspec` — запустить тесты

## Конвенции
- Паттерн MVC
- Паттерн service objects

## Ограничения
- Не устанавливать новые гемы без согласования.
- Если появляется ошибка при реализации способом, который рекомендовал пользователь, сначала сообщить об ошибке и предложить варианты решения.
- Ничего не менять вне проекта `ai-setup`.
