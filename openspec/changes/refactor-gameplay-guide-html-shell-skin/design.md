# Design: Gameplay Guide Embedded HTML Shell Skin Refactor

## Context
- 当前 GameplayGuideWindow 已实现完整目录与分页逻辑，属于可用业务基线。
- 项目已有嵌入式 WebView 先例（背包壳、法杖编辑器壳、菜单壳），并有回退策略沉淀。
- 本次需求明确为视觉壳重构，不允许逻辑内容漂移。

## Goals / Non-Goals
- Goals:
  - 以 guide 项目 HandbookWindow 风格重建引导窗口视觉层。
  - 保持 Godot 为权威状态源，HTML 仅做渲染与意图转发。
  - 在 WebView 异常时无损回退原生窗口。
  - 桌面端通过一致性与可用性验收。
- Non-Goals:
  - 不改引导章节数据、分页算法、图鉴生成逻辑。
  - 不改 HUD 打开入口、快捷键与暂停策略。
  - 不承诺本次覆盖移动端高保真适配。

## Decisions

### Decision 1: Strict shell boundary
Gameplay guide 改造采用“薄壳”边界：
- Godot 侧负责：目录构建、页面索引、内容组装、翻页状态、资源加载与业务语义。
- HTML 侧负责：视觉渲染、交互事件回传、焦点反馈。

Rationale:
- 最大化复用当前稳定逻辑，降低回归风险。
- 符合“换壳不换核”的需求约束。

### Decision 2: Canonical content source remains Godot
内容与结构以现有 GuideSectionData + GameplayGuideWindow 目录树为唯一权威来源，HTML 不引入独立 guide-data 主数据。

Rationale:
- 防止双数据源导致章节顺序、文案、翻译键漂移。
- 保障 1:1 内容一致性可验证。

### Decision 3: WebView-first with mandatory native fallback
运行时默认尝试 HTML 壳；若出现任一不可恢复异常（WebView 类缺失、壳资源缺失、桥接握手失败、运行期桥接中断），立即切回现有原生窗口并保持功能可用。

Rationale:
- 对齐项目既有嵌入策略与稳定性原则。
- 防止 UI 壳问题阻断玩家核心引导阅读能力。

### Decision 4: Desktop acceptance gate
本次强制验收平台为桌面，移动端允许降级路径（原生窗口或低保真壳）但不阻塞交付。

Rationale:
- 当前 WebView 插件与输入焦点行为在桌面链路更成熟。
- 缩小首批交付面，先确保高优先平台可用。

## Architecture

### Runtime flow
1. 玩家打开引导窗口。
2. UI 路由尝试创建 HTML 壳实例并进行握手。
3. 成功：Godot 下发当前页面状态快照，HTML 渲染；用户操作以意图消息回传。
4. 失败：记录告警并切换原生 GameplayGuideWindow，维持同等功能。

### Bridge contract (high-level)
- Godot -> HTML:
  - guide_state_snapshot: 当前目录树、当前页索引、总页数、页面内容（title/path/content/image metadata）。
  - guide_page_changed: 翻页/选页后的增量状态。
- HTML -> Godot:
  - guide_select_page(index)
  - guide_prev_page
  - guide_next_page
  - guide_close
- Guardrails:
  - HTML 不得发送改写数据源结构的命令。
  - Godot 对所有入站消息做类型与范围校验。

## Risks / Trade-offs
- Risk: 风格高保真还原可能与现有布局密度冲突。
  - Mitigation: 以逻辑与布局可读性优先，视觉细节通过 token 微调。
- Risk: WebView 焦点捕获导致快捷键穿透或失效。
  - Mitigation: 复用既有输入焦点门控策略，增加打开/关闭/失焦回归用例。
- Risk: 双端渲染状态不同步导致翻页显示错误。
  - Mitigation: 采用 Godot 单一权威索引，HTML 仅显示 server-authoritative 状态。

## Validation Strategy
- 逻辑一致性：目录点击、上一页/下一页、页码、图像显隐行为与原生窗口一致。
- 内容一致性：同一页面标题、路径、正文逐项一致。
- 回退一致性：注入 WebView 初始化失败与桥接失败，验证自动回退且功能可继续。
- 桌面验收：主流窗口尺寸下可读性、布局完整性、输入可用性通过。

## Open Questions
- 当前无阻塞性未决问题，可进入评审。

## Implementation Details (2026-04-09)

### Delivered Files
- `src/ui/guide/gameplay_guide_window.gd`
  - Added WebView-first bootstrap: `_try_setup_web_guide_shell()`.
  - Added mandatory fallback path: `_activate_native_fallback()`.
  - Added watchdog-based readiness guard: `_start_web_ready_watchdog()`.
  - Added state sync payload builder: `_build_web_guide_payload()`.
  - Added catalog snapshot serializer: `_build_catalog_snapshot()` + `_serialize_catalog_item()`.
  - Added shell IPC handler: `_on_guide_web_ipc_message()`.
  - Hardened close/open lifecycle for input focus safety: close now releases WebView focus and destroys the WebView instance (`_release_web_shell_focus`, `_destroy_web_shell_instance`), and open recreates it on demand (`_ensure_web_shell_instance`) to prevent hidden WebView keyboard capture/beep after closing.
  - Added stronger focus-capture guardrails for godot_wry backends: lazy WebView creation on demand (no startup pre-focus), disable focus-on-create (`set_focused_when_created(false)`), and explicit input-forward toggle + parent focus handoff when hidden (`set_forward_input_events(false)` + `focus_parent()`).
  - Preserved canonical page/catlog logic and reused existing `_select_page`, `_on_prev_pressed`, `_on_next_pressed`.
- `ui/web/gameplay_guide_shell/index.html`
  - New static shell implementing HandbookWindow-inspired pixel sci-fi visual layer.
  - Implemented bridge handshake and inbound state rendering.
  - Implemented intent emission for `guide_select_page`, `guide_prev_page`, `guide_next_page`, `guide_close`.
  - Implemented BBCode-to-HTML presentation transform for existing content text.
- `ui/web/gameplay_guide_shell/README.md`
  - Added shell scope and bridge contract notes.
- `v1.0.0/export_presets.cfg`
  - Added `ui/web/gameplay_guide_shell/*` to `include_filter` for packaged export coverage.

### Runtime Authority Boundary (Implemented)
- Godot remains source of truth for:
  - page list content
  - catalog hierarchy
  - current page index and navigation constraints
- HTML shell acts as:
  - render layer
  - user-intent forwarder via IPC

### Implemented IPC Contract
- Shell -> Godot:
  - `guide_ready`
  - `guide_request_state`
  - `guide_select_page`
  - `guide_prev_page`
  - `guide_next_page`
  - `guide_close`
- Godot -> Shell:
  - `guide_state` with `pages`, `catalog`, `current_page_index`, `texts`, and serialized `image_data_url`.

### Fallback Triggers (Implemented)
- WebView class unavailable.
- WebView instantiation failure.
- Shell resource missing.
- Bridge readiness timeout (watchdog).
- Runtime post_message unavailable.
- Runtime bridge error event.

### Scope Integrity Notes
- No changes were made to HUD entry flow.
- No changes were made to guide content model (`GuideSectionData`) or chapter semantics.
- No changes were made to page generation logic for spell compendium and section pages.

### Visual Parity Refresh (2026-04-09)
- Updated `ui/web/gameplay_guide_shell/index.html` from the previous minimal shell to a higher-fidelity handbook layout aligned with the provided reference direction while keeping pixel-style language.
- Refined sidebar information architecture:
  - Added explicit `目录导航` head/meta region and stronger selected-row emphasis.
  - Added hierarchical symbol mapping for top-level sections (`魔法/世界/NPC/继承`) to improve category scanability.
- Refined content panel readability:
  - Added breadcrumb/tag row, larger title hierarchy, and progress track in footer.
  - Added structured content rendering (`段落/要点列表/键值信息块/提示与警告 callout`) from existing Godot-side text payload without introducing a second data source.
- Scope guard remains unchanged:
  - No runtime protocol expansion; IPC contract stays `guide_state` + intent messages.
  - No behavior changes to page indexing, catalog authority, or navigation semantics.

### Layout Parity Pass-2 (2026-04-09)
- Reworked `ui/web/gameplay_guide_shell/index.html` to mirror the reference handbook shell structure more directly:
  - Fixed-size centered handbook window (`max 1200x750`) with pixel panel corners.
  - Explicit two-column frame: left `260px` navigation rail + right content reader area.
  - Bottom action bar aligned to handbook semantics (`目录` / `搜索` / `上一页` / `下一页` + progress rail + page indicator).
- Visual token alignment moved closer to handbook baseline:
  - Sidebar/reader backgrounds switched to `#121830` / `#0A0E1A` family.
  - List item interaction updated to left border highlight (`hover/active`) instead of previous glow-card style.
  - Reader typography switched to compact pixel hierarchy (`title underline`, `pixel breadcrumb`, `dense body leading`).
- Runtime contract unchanged while improving UX affordance:
  - Kept existing IPC message set and payload shape.
  - Added local-only actions (`目录` jump to first page, `搜索` focus shortcut) without protocol expansion.

### Layout Lock Fix (2026-04-09)
- Enforced desktop-first two-column lock in `ui/web/gameplay_guide_shell/index.html`:
  - Switched body layout from flex fallback behavior to explicit grid columns (`260px + 1fr`).
  - Removed responsive stack behavior that previously converted the shell to top/bottom layout under narrower embedded viewport sizes.
- Added narrow-width fallback that still keeps left/right split (`220px` then `180px` sidebar), preventing regression to vertical stacking.

### Guide Resource Parse-Order Fix (2026-04-09)
- Root cause identified:
  - Multiple guide data `.tres` files declared `[resource]` before `[sub_resource]` and referenced `SubResource(...)` IDs before those IDs were declared.
  - Godot text resource loader rejected these forward references, causing repeated parse errors while building guide pages.
- Implemented correction:
  - Reordered declarations so every `[sub_resource]` block is defined before the final `[resource]` block that references them.
  - Applied to: `data/guide/world.tres`, `data/guide/npc_interaction.tres`, `data/guide/inheritance.tres`, `data/guide/magic.tres`, `data/guide/magic_building_guide.tres`, and aligned legacy guide files `data/guide/combat.tres`, `data/guide/movement.tres`, `data/guide/inventory.tres`.
- Behavioral impact:
  - No guide content or hierarchy logic changed.
  - Fix is structural-only for text resource parse compatibility.

### Subsections Nil-Guard Fix (2026-04-09)
- Root cause identified:
  - In `GameplayGuideWindow._append_pages_from_section`, fallback branch used `section.get("subsections")` directly.
  - For resources missing `subsections`, `get(...)` returned `Nil`, which was assigned to `raw_subsections: Array`, triggering runtime type error.
- Implemented correction:
  - Added type guard before assignment: only assign when `maybe_subsections is Array`; otherwise keep default empty array.
  - Applied to: `src/ui/guide/gameplay_guide_window.gd` and mirrored upload copy `guide/upload/gameplay_guide_window.gd`.
- Behavioral impact:
  - No chapter hierarchy or content semantics changed.
  - Fix only hardens fallback data-reading path against missing keys.

### Guide `<null>` Catalog Fix (2026-04-09)
- Root cause identified:
  - Some fallback `.tres` loads entered generic `get(...)` branch and returned null values for `title/description/content`, which were previously converted with `str(null)` into literal `<null>`.
  - Guide resources relied on class metadata only; under fallback load paths this could degrade subsection extraction.
- Implemented correction:
  - Added safe accessor helpers in `GameplayGuideWindow` (`_safe_get_string`, `_safe_get_array`) and replaced direct `str(section.get(...))`/`str(subsection.get(...))` calls.
  - Added explicit script binding in guide resources (`script = ExtResource(...)`) for both section resource and subsection sub-resources to stabilize data model loading.
  - Applied to runtime script and upload mirror:
    - `src/ui/guide/gameplay_guide_window.gd`
    - `guide/upload/gameplay_guide_window.gd`
    - `data/guide/*.tres` (all guide section files)
- Behavioral impact:
  - UI no longer renders `<null>` for section/page titles when fallback path is hit.
  - Missing/invalid fields now degrade to explicit defaults instead of leaking null markers.
