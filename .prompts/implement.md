Ты реализуешь фичу по документам memory-bank.

Перед изменениями прочитай:
- `AGENTS.md`
- `memory-bank/features/FT-XXX/feature.md`
- `memory-bank/features/FT-XXX/implementation-plan.md`
- `memory-bank/engineering/coding-style.md`
- `memory-bank/engineering/testing-policy.md`

Алгоритм работы:
1. Сверь scope и non-scope из `feature.md`.
2. Выдели конкретные шаги из `implementation-plan.md`.
3. Сделай минимальные изменения в коде, покрывающие только `REQ` этой фичи.
4. Запусти релевантные тесты из `CHK-*`.
5. В отчёте покажи соответствие: какие `REQ` закрыты и чем проверены.

Ограничения:
- Не добавлять новые gem без согласования.
- Если предложенный пользователем путь даёт ошибку, сначала сообщи об этом и предложи варианты.
