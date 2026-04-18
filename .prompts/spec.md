Ты готовишь или обновляешь feature-спеку в `memory-bank/features/FT-XXX/feature.md`.

Контекст для чтения:
- `AGENTS.md`
- `PRD.md`
- `memory-bank/prd/PRD-001-task-generator-mvp.md`
- `memory-bank/domain/problem.md`
- `memory-bank/domain/architecture.md`
- `memory-bank/engineering/testing-policy.md`

Требования к результату:
1. Сформулируй `Problem`, `Outcome`, `Scope`, `Non-Scope`, `Constraints`.
2. Добавь `Flow`, `Contracts`, `Failure Modes`.
3. Опиши `Verify`: `Exit Criteria`, `Checks`, `Evidence`.
4. Построй traceability `REQ -> EC -> CHK`.

Правила:
- Не уходи в implementation sequencing внутри `feature.md`.
- Любой новый error-code или API-контракт должен быть явно обоснован.
