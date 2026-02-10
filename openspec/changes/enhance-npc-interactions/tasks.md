# Implementation Tasks

## Phase 1: Foundations & Visuals
- [x] **Specs**: Define specific visual requirements for MinimalistEntity badges and rings. <!-- id: spec-visuals -->
- [x] **Engine**: Extend `MinimalistEntity.gd` to support drawing "Relationship Rings" and "Occupation Badges". <!-- id: impl-minimalist-ext -->
- [x] **Engine**: Create `VisualCueComponent.gd` to attach to NPCs for handling distance-based UI state (Nameplate -> Icon -> Prompt). <!-- id: impl-visual-cue-comp -->
- [x] **Engine**: Integrate `VisualCueComponent` into `BaseNPC.tscn`. <!-- id: impl-npc-integration -->

## Phase 2: Contextual Interactions
- [x] **Specs**: Define interaction context rules (Time/Relationship/Quest). <!-- id: spec-context -->
- [x] **Engine**: Implement `ContextAwarePrompts` logic in `BaseNPC` to return dynamic action lists. <!-- id: impl-context-logic -->
- [x] **UI**: Create `ContextPrompt` widget (floating UI above head) handling Primary/Secondary keys. <!-- id: impl-prompt-ui -->

## Phase 3: Trading & Dialogue
- [x] **Specs**: Define Trading UI layout and discount logic. <!-- id: spec-trading -->
- [x] **UI**: Create `TradeWindow.tscn` (Cart style). <!-- id: impl-trade-window -->
- [x] **Engine**: Implement `TradeManager` logic (price calculation, inventory transfer). <!-- id: impl-trade-logic -->
- [x] **UI**: Enhance `DialogueWindow` to support "leads_to" navigation and relationship-gated options. <!-- id: impl-dialogue-enh -->

## Phase 4: Feedback & Polish
- [x] **Specs**: Define feedback FX types. <!-- id: spec-feedback -->
- [x] **UI**: Create `FeedbackManager` and effect scenes (Floating Icons, Particles). <!-- id: impl-feedback-sys -->
- [x] **Engine**: Trigger feedback events on relationship change or trade success. <!-- id: impl-feedback-trigger -->
- [x] **Settings**: Add A11y options to `SettingsManager`. <!-- id: impl-a11y -->
