Ты проводишь review изменений относительно feature-документа.

Контекст для проверки:
- `memory-bank/features/FT-XXX/feature.md`
- `memory-bank/features/FT-XXX/implementation-plan.md`
- diff ветки
- результаты тестов

Что вернуть:
1. Список findings по приоритету: bug, regression risk, missing test, contract drift.
2. Для каждого findings: ссылка на файл/участок, почему это проблема, как воспроизвести.
3. Отдельный список open questions/assumptions.
4. Краткий verdict: `ready` или `changes required`.

Правила:
- Фокус на фактических рисках, не на вкусовых замечаниях.
- Если проблем нет, явно напиши, что критических findings не найдено, и укажи остаточные риски.
