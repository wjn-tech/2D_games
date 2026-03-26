## 1. Specification and Mapping Contracts
- [x] 1.1 Define the 107-step terrain compatibility catalog contract (indexing, statuses, skip governance fields).
- [x] 1.2 Define deterministic skip policy with allowed reason categories and mandatory compatibility notes.
- [x] 1.3 Define alignment report outputs (implemented/adapted/skipped counts, unresolved entries).

## 2. Startup Full-Preload Contracts
- [x] 2.1 Define planetary-mode startup gate that blocks `PLAYING` until full preload completion.
- [x] 2.2 Define preload domain rules (which chunk ranges are mandatory for completion) and legacy fallback behavior.
- [x] 2.3 Define preload failure/timeout handling and user-facing failure states.

## 3. Preload Performance and Readiness Contracts
- [x] 3.1 Define deterministic bounded-batch preload execution and progress telemetry requirements.
- [x] 3.2 Define checkpoint/resume requirements for interrupted preload sessions.
- [x] 3.3 Define post-handoff readiness guarantee: no first-time generation work for in-domain chunks.

## 4. Cross-Change Integration
- [x] 4.1 Link this change with staged-pass, topology-wrap, and streaming budget capabilities to avoid conflicting semantics.
- [x] 4.2 Document compatibility assumptions for existing bedrock boundary and critical/enrichment split.

## 5. Validation
- [x] 5.1 Verify each new requirement includes at least one valid `#### Scenario:` block.
- [x] 5.2 Validate OpenSpec artifacts: `openspec validate align-worldgen-to-terraria-107-steps-and-full-preload --strict`.
- [x] 5.3 Resolve all validation errors before review handoff.
