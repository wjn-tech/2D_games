# Gameplay Guide HTML Shell

Static shell resources for Gameplay Guide WebView embedding.

## Runtime entry
- index.html

## Bridge contract
- Outbound (shell -> Godot):
  - guide_ready
  - guide_request_state
  - guide_select_page
  - guide_prev_page
  - guide_next_page
  - guide_close
- Inbound (Godot -> shell):
  - guide_state

## Scope
- This shell is presentation-only.
- Guide logic, page indexing, and canonical content remain in Godot `GameplayGuideWindow`.

## Fallback expectation
- If WebView runtime or bridge fails, Godot must fall back to native gameplay guide UI.
