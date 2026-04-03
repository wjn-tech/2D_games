# Change: Add Hostile Drop Localization (ZH/EN)

## Why
用户已确认怪物掉落需要明确中文名称，并要求形成可审阅、可维护的本地化键值方案。

当前掉落命名正在从概念 ID 走向正式资源，若没有统一 key 命名和中英映射，后续 UI、掉落提示、存档兼容和策划维护会快速失控。

## What Changes
- 新增“敌对掉落本地化命名规范”能力，覆盖 `add-hostile-unique-drop-tables` 中定义的签名掉落与通用怪物材料。
- 定义统一 key 规则：
  - Signature: `ITEM_HOSTILE_<MONSTER>_<TOKEN>`
  - Common material: `ITEM_HOSTILE_MAT_<TOKEN>`
- 为每个掉落 item_id 提供双语映射：`item_id -> translation_key -> zh -> en`。
- 规定掉落文案的最小验收：
  - 中文名称自然可读，符合怪物语义。
  - 英文名称语义一致，避免机翻式断裂。
- 与现有本地化提案 `localize-ui-and-settings` 保持兼容，不重复定义全局语言系统。

## Scope
- In scope:
  - 怪物掉落项目（签名+通用材料）的中英命名与 key 规范。
  - `assets/translations.csv` 新增键值的组织规范。
  - 与 `add-hostile-unique-drop-tables` 的字段对齐约束。
- Out of scope:
  - 全量 UI 的国际化改造。
  - 非怪物掉落类物品命名重构。
  - 对话系统文案重写。

## Impact
- Affected specs:
  - hostile-drop-localization (new)
- Related changes:
  - add-hostile-unique-drop-tables
  - localize-ui-and-settings
- Affected files (implementation stage):
  - `assets/translations.csv`
  - `data/items/hostile/*.tres` (planned)
  - `docs/hostile_spawn_table.md` (reference section)
