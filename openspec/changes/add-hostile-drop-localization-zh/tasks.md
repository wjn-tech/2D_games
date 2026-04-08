## 1. Naming Contract
- [x] 1.1 Define translation-key format for hostile signature drops and hostile common materials.
- [x] 1.2 Define naming style guide (tone, length, forbidden patterns, bilingual consistency checks).
- [x] 1.3 Define fallback strategy when a translation key is missing at runtime.

## 2. Localization Matrix
- [x] 2.1 Produce full matrix for all signature drops (8 hostile types): item_id, key, zh, en.
- [x] 2.2 Produce full matrix for all common hostile materials in the drop design: item_id, key, zh, en.
- [x] 2.3 Verify no duplicate keys and no duplicate zh names that cause gameplay ambiguity.

## 3. Integration Rules
- [x] 3.1 Define linkage contract between drop-table item_id and localization key.
- [x] 3.2 Define rule that drop-table review cannot pass if item_id has no localization row.
- [x] 3.3 Define compatibility notes with existing direct `display_name` UI paths.

## 4. Validation
- [x] 4.1 Add checklist for bilingual review (readability, semantic match, consistency).
- [x] 4.2 Add strict coverage checks: 100% hostile drop entries mapped to localization keys.
- [x] 4.3 Run `openspec validate add-hostile-drop-localization-zh --strict` and resolve all issues.
