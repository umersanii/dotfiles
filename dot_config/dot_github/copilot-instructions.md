# Copilot Instructions

## Scope
- This workspace is a personal Linux config repo rooted at `/home/sani/.config`.
- Prioritize minimal, targeted edits to existing files.
- Do not introduce framework-level refactors unless explicitly requested.

## Environment Assumptions
- OS: Arch Linux on Wayland/Hyprland.
- Shell tooling may include `bash`, `fish`, `kitty`, and `starship`.
- Quickshell and Hyprland configs are actively used and should remain stable.

## Editing Rules
- Preserve existing formatting and style in each file.
- Avoid renaming files, moving directories, or changing load order unless asked.
- Keep changes local to the requested feature/fix.
- Do not add placeholders, TODO stubs, or dead config blocks.

## Safety & Stability
- Prefer non-destructive changes to user settings.
- Never remove user keybinds, startup commands, or theme defaults without explicit instruction.
- If a change may impact startup/session behavior, call it out clearly in the response.

## Quickshell / QML Guidance
- Maintain existing component structure under `quickshell/ii/`.
- Reuse current property names, signal patterns, and imported modules.
- Keep UI logic simple and avoid introducing unnecessary abstractions.
- Do not hardcode new color systems if theme tokens or shared style values already exist.

## Config-Specific Practices
- For shell configs (`fish`, `bash`, `zshrc.d`), avoid aliases/functions that shadow core commands unless intentional.
- For Hyprland configs, keep rules and bindings consistent with current modular layout.
- For app configs (kitty, fuzzel, btop, cava, mpv), only adjust keys relevant to the request.

## Validation
- After edits, run the smallest practical validation step when possible.
- Prefer lint/parse checks for the touched file type.
- If runtime validation is needed (e.g., reloading quickshell), provide the exact command and expected outcome.

## Response Expectations
- Summarize exactly what changed and where.
- Mention any assumptions.
- Suggest the most relevant next verification step only.