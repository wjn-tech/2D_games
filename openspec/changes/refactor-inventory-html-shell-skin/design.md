## Context
The project has a stable Godot-native inventory UI and inventory runtime logic. A new visual style exists in inventory_ui/src/app/page.tsx, and the requested outcome is to replace only the presentation shell while preserving all inventory-related logic 1:1.

Current codebase patterns already include embedded WebView shells and fallback behavior in other modules (for example menu and wand editor paths). This change reuses those architectural patterns for InventoryWindow.

## Goals / Non-Goals
### Goals
- Replace InventoryWindow visual shell with an embedded HTML shell.
- Keep all existing inventory gameplay logic and behavior unchanged.
- Preserve existing text/localization behavior.
- Provide mandatory native fallback when WebView or HTML resources fail.
- Use static build artifacts from inventory_ui (no runtime Next server dependency).

### Non-Goals
- No refactor of inventory gameplay logic.
- No scope expansion to CharacterPanel, TradeWindow, or other windows.
- No full-project UI HTML migration.
- No mobile platform guarantee in this change.

## Decisions
### 1) Scope Freeze: InventoryWindow Only
- Decision: limit this change to InventoryWindow.
- Rationale: minimizes behavioral risk and preserves rollout safety.

### 2) Authority Model: Godot Owns State and Logic
- Decision: HTML shell is render and intent layer only.
- Rationale: prevents divergence from existing gameplay behavior.
- Rule: all effective inventory mutations execute through existing Godot logic paths.

### 3) Bridge Protocol: Intent-Only Messages
- Decision: HTML emits user intent, Godot validates and applies.
- Rationale: strict 1:1 logic preservation and easier regression validation.
- Example intent categories: move item, use item, drop item, switch tab, close window.

### 4) Visual Baseline: inventory_ui/src/app/page.tsx
- Decision: use that file as the canonical style source.
- Rationale: removes ambiguity between multiple style candidates.

### 5) Build/Packaging: Static Export Pipeline
- Decision: generate static HTML/CSS/JS from inventory_ui and package into ui/web/inventory_shell.
- Rationale: deterministic runtime behavior and offline compatibility.

### 6) Runtime Target: Windows First + Fallback
- Decision: optimize initial acceptance for Windows desktop WebView2 path.
- Rationale: user-selected target and existing plugin/runtime assumptions.
- Rule: if WebView path fails, auto-open native InventoryWindow content.

## Architecture Outline
1. InventoryWindow open request resolves shell availability.
2. If WebView + HTML are available, show HTML shell and push inventory snapshot.
3. HTML actions are sent as typed intents to Godot.
4. Godot applies existing logic and pushes updated snapshot back to HTML.
5. On any bridge/runtime failure, hide shell and activate native fallback UI.

## Risks / Trade-offs
- Risk: visual shell can accidentally alter interaction timing.
  - Mitigation: intent-only bridge and parity tests against current behavior.
- Risk: static export drift from source visual project.
  - Mitigation: document deterministic build/export steps and artifact checks.
- Risk: WebView runtime variance across machines.
  - Mitigation: strict fallback policy and clear warning paths.

## Validation Strategy
- Logic parity checks: drag/drop, use, drop, hotbar sync, crafting tab, close flow.
- Persistence checks: save/load inventory state unchanged.
- Fallback checks: missing HTML, missing WebView class, bridge error recovery.
- Visual checks: shell matches style baseline while preserving existing localized text.

## Implementation Traceability (2026-04-09)
- Runtime shell entry is implemented in `src/ui/inventory/inventory_ui.gd` via `WEB_SHELL_RESOURCE_PATH = "ui/web/inventory_shell/index.html"` and `_try_setup_web_inventory_shell()`.
- Packaging requirement is implemented in both `export_presets.cfg` and `v1.0.0/export_presets.cfg` via wildcard `include_filter` entries (`ui/web/*` shell folders + `addons/godot_wry` runtime binaries).
- Fallback diagnostics are implemented in `_resolve_webview_url()` and `_try_setup_web_inventory_shell()` to explicitly point to export include filter coverage and Windows runtime prerequisites (WebView2 + VC++ x64).
- Bridge bootstrap resilience is implemented by treating `inventory_request_state` as a valid readiness signal in `src/ui/inventory/inventory_ui.gd`, and by retrying `inventory_ready`/`inventory_request_state` handshake in both `ui/web/inventory_shell/index.html` and `inventory_ui/public/inventory_shell/index.html`.
- Runtime validation practice includes checking `v1.0.0/ui/web/inventory_shell/index.html` presence for already-exported binaries to avoid stale package diagnostics.
- Runtime input-focus safety is hardened in `src/ui/inventory/inventory_ui.gd`: WebView now disables focus-on-create (`set_focused_when_created(false)`), toggles keyboard forwarding with visibility (`set_forward_input_events`), hands focus back to parent (`focus_parent`) on hide/close, and is eagerly disposed during close to prevent post-close WASD beep capture.
