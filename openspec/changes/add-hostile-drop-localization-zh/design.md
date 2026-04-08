## Context
`add-hostile-unique-drop-tables` 已定义怪物掉落 item_id 方向，但尚未形成正式的中英命名和 key 规范。

现有工程中语言设置由 `TranslationServer.set_locale(...)` 管理；但部分物品 UI仍直接读取 `item.display_name`。这意味着本次设计必须兼顾“键值可扩展”和“当前链路可读性”。

## Goals / Non-Goals
- Goals:
  - 建立 hostile drop 专属本地化键值规范。
  - 为全部掉落条目提供中英双语映射清单。
  - 保证中文审阅体验可直接使用。
- Non-Goals:
  - 不在本提案阶段改动 UI 脚本。
  - 不替换现有全局本地化架构。

## Key Decisions
- Decision: 所有 hostile drop 条目都必须有稳定 translation key。
- Decision: 中文名称作为策划审阅主文案，英文名称作为跨语言对照文案。
- Decision: 兼容现有链路，实施阶段允许短期双轨：
  - Resource `display_name` 存中文可读名（防止未接入 `tr()` 的 UI 显示 key）
  - 同时在 `translations.csv` 提供标准 key 供未来统一 `tr()`

## Hostile Drop Localization Matrix (Draft)

### Signature Drops
| item_id | translation_key | zh | en |
| --- | --- | --- | --- |
| slime_essence | ITEM_HOSTILE_SLIME_ESSENCE | 史莱姆精华 | Slime Essence |
| bog_core | ITEM_HOSTILE_BOG_CORE | 沼泽泥核 | Bog Core |
| rotten_talisman | ITEM_HOSTILE_ZOMBIE_TALISMAN | 腐朽护符 | Rotten Talisman |
| bone_fragment | ITEM_HOSTILE_SKELETON_FRAGMENT | 骨片 | Bone Fragment |
| echo_wing | ITEM_HOSTILE_CAVEBAT_WING | 回音翼膜 | Echo Wing |
| frost_gland | ITEM_HOSTILE_FROSTBAT_GLAND | 霜寒腺体 | Frost Gland |
| antlion_mandible | ITEM_HOSTILE_ANTLION_MANDIBLE | 蚁狮颚钳 | Antlion Mandible |
| void_eyeball | ITEM_HOSTILE_DEMONEYE_EYEBALL | 虚空魔眼 | Void Eyeball |

### Common Hostile Materials
| item_id | translation_key | zh | en |
| --- | --- | --- | --- |
| gelatin_residue | ITEM_HOSTILE_MAT_GELATIN_RESIDUE | 胶质残渣 | Gelatin Residue |
| arcane_dust | ITEM_HOSTILE_MAT_ARCANE_DUST | 奥术尘 | Arcane Dust |
| toxic_slurry | ITEM_HOSTILE_MAT_TOXIC_SLURRY | 毒沼浆 | Toxic Slurry |
| tainted_flesh | ITEM_HOSTILE_MAT_TAINTED_FLESH | 污染腐肉 | Tainted Flesh |
| torn_cloth | ITEM_HOSTILE_MAT_TORN_CLOTH | 破败布片 | Torn Cloth |
| bone_dust | ITEM_HOSTILE_MAT_BONE_DUST | 骨尘 | Bone Dust |
| cursed_powder | ITEM_HOSTILE_MAT_CURSED_POWDER | 咒蚀粉末 | Cursed Powder |
| bat_fur | ITEM_HOSTILE_MAT_BAT_FUR | 蝠绒 | Bat Fur |
| sonar_membrane_shard | ITEM_HOSTILE_MAT_SONAR_SHARD | 声呐膜片 | Sonar Membrane Shard |
| frozen_membrane | ITEM_HOSTILE_MAT_FROZEN_MEMBRANE | 冻膜 | Frozen Membrane |
| chill_dust | ITEM_HOSTILE_MAT_CHILL_DUST | 寒霜尘 | Chill Dust |
| chitin_fragment | ITEM_HOSTILE_MAT_CHITIN_FRAGMENT | 几丁碎片 | Chitin Fragment |
| desert_resin | ITEM_HOSTILE_MAT_DESERT_RESIN | 沙蜡树脂 | Desert Resin |
| shadow_ichor | ITEM_HOSTILE_MAT_SHADOW_ICHOR | 影蚀体液 | Shadow Ichor |
| arcane_shard | ITEM_HOSTILE_MAT_ARCANE_SHARD | 奥术碎晶 | Arcane Shard |

## Validation Strategy
- Coverage: hostile drop matrix 100% rows have translation keys.
- Consistency: key format/monster tag/token naming pass regex checks.
- Readability: 中文名避免过长或歧义；英文名与中文语义一一对应。
- Compatibility: 在未全面 `tr()` 改造前，`display_name` fallback 不影响可玩性。
