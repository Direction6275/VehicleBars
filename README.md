# Vehicle Bars

A small Retail WoW 12.1 addon for a reversed main action bar: `= - 0 9 8 7 6 5 4 3 2 1` from left to right.

While a vehicle, override, or possession action bar is active, Vehicle Bars mirrors your actual main-bar bindings across all 12 slots. With your setup, vehicle abilities use `1 2 3 4 5 6 7 8 9 0 - =` in Blizzard's slot order. Your normal bindings resume automatically afterward. The binding fix needs no configuration. When ElvUI action bars are enabled, the addon also registers as an ElvUI plugin and shows a compact vehicle HUD.

| Vehicle ability slot | Uses the keys normally bound to main-bar slot | Your key |
| --- | --- | --- |
| 1 | 12 | 1 |
| 2 | 11 | 2 |
| 3 | 10 | 3 |
| 4 | 9 | 4 |
| 5 | 8 | 5 |
| 6 | 7 | 6 |
| 7 | 6 | 7 |
| 8 | 5 | 8 |
| 9 | 4 | 9 |
| 10 | 3 | 0 |
| 11 | 2 | - |
| 12 | 1 | = |

The addon follows all keys assigned to those slots, including secondary bindings. It does not hard-code the number row. Vehicle hotkey labels reflect the temporary mapping; ability icons stay in Blizzard's order. Saved keybindings and action placements are never rewritten.

An Exit/Leave/End **ability** keeps its Blizzard-assigned slot, so it receives that slot's intended key. Vehicles with six abilities still use slots 1 through 6. ElvUI's bar-1 vehicle-exit button in slot 12 therefore uses your `=` key. The separate vehicle exit control and its dedicated binding are unchanged.

## Install

Download an addon ZIP from [GitHub Releases](https://github.com/Direction6275/VehicleBars/releases), then extract it into your Retail `Interface/AddOns` directory. The result should be `Interface/AddOns/VehicleBars/VehicleBars.toc`. Restart WoW if it was running when you added the folder, and enable **Vehicle Bars** on the character selection AddOns screen.

Use `/vehiclebars` to report the version, detected bar provider (ElvUI or Blizzard), and whether the vehicle mapping is active. To remove it, disable the addon and reload. HUD preferences and its mover position are stored in your ElvUI profile; the addon does not save a separate database.

## Compact ElvUI HUD

The clickable HUD shows populated ElvUI bar-1 vehicle slots, their effective keybinds, cooldowns, counts, and a highlight while a key is pressed. Empty slots consume no width when the layout is established. During combat, button positions stay fixed; slot additions/removals are reflected in the layout after combat ends. For example, occupied slots 1, 3, and 12 appear beside one another with labels `1`, `3`, and `=`. ElvUI's custom exit button is included when present.

- Use ElvUI's **Toggle Anchors** and move **Vehicle HUD**, or type `/vehiclebars move`. ElvUI saves the position in the active profile and provides its normal snapping and nudging tools.
- Open **ElvUI > Vehicle Bars** to enable/disable the HUD, change icon size or spacing, preview it, or open its mover. The default is 36-pixel icons with 4-pixel spacing.
- `/vehiclebars preview` toggles a four-icon preview outside vehicles. Opening its mover also provides a preview. Preview ends when combat begins; active vehicles show real abilities.
- Left-click a HUD button to activate its action, including during combat, or keep using your existing keys. Hover for the corresponding ElvUI ability/exit tooltip and effective key. Preview icons have explanatory tooltips and cannot activate actions.
- The HUD uses protected action buttons. A vehicle/page transition establishes a compact layout even in combat; ordinary slot changes then keep the current positions fixed until combat ends. An emptied slot becomes transparent and cannot cast; newly populated slots join the HUD after combat. Icon size, spacing, visibility, and mover changes are available outside combat.
- Hotkeys remain visible in the HUD even if you hide them on the main ElvUI bar. Fonts/borders use ElvUI styling and cooldown text uses its action-bar cooldown settings.
- Outside vehicle/override/possession mode, the HUD hides. Turning the HUD off leaves the working key reversal enabled.
- Ordinary ElvUI action bars remain in place. This adds a movable display; it does not replace or reposition them.

## Scope

- Supports Blizzard's standard action bars and ElvUI bar 1. ElvUI is detected automatically; vehicle keys click its own secure buttons, preserving its paging, key-down/key-up behavior, and hotkey styling. Other bar replacements require separate support.
- Covers dedicated vehicle bars and vehicle/override/possession abilities shown on the main bar. Ordinary bar paging and class stances retain your normal mapping. Pet battles are excluded.
- Entering and leaving vehicles uses a secure state driver, including during combat. Editing bindings during combat queues a refresh until combat ends; a vehicle state transition also reads the current bindings.
- Enable this addon on characters whose main bar you want mirrored in vehicles. It always mirrors; it does not detect whether a character uses reversed or default bindings.

## Validation

The implementation was checked against Blizzard's local Retail `live` source snapshot `8ea15b61e45c0ed4eba01439c90757f86eb78d34`, including native action dispatch, secure state drivers, restricted binding methods, and hotkey rendering. ElvUI integration was checked against the installed ElvUI v15.26 action-bar module and its bundled LibActionButton-1.0. It has Lua 5.1 and mocked behavior checks. The user confirmed the 1.0.1 ElvUI key-routing fix works in game. The user also confirmed the 1.1.0 display HUD works in game. Version 1.2.0 adds protected mouse interaction and tooltips with Lua/mock coverage; these new paths still need in-game validation.

Before relying on it, test a familiar vehicle: first ability, secondary abilities, any end/leave ability, displayed labels, and return to your normal bar. Also test entry/exit in combat, a vehicle with a main-bar replacement, and both key-down/key-up activation settings. For the HUD, test left-click abilities and exit, key-down/key-up settings, hover tooltip content/cleanup, harmless preview clicks, combat vehicle entry/exit, frozen positions on mid-combat slot changes and compaction afterward, exact key labels, cooldowns, press feedback, mover persistence after reload, and ElvUI profile changes. Check for Lua errors or blocked-action warnings.

## Changes in 1.0.1

Fix vehicle keys doing nothing with ElvUI action bars. Route temporary bindings to ElvUI bar-1 buttons instead of the hidden Blizzard buttons, and update ElvUI labels while respecting its styling and hidden-hotkey setting.

## Changes in 1.1.0

Add an optional ElvUI plugin with a compact, display-only vehicle HUD. Populated slots pack together, including the exit slot, with the current key labels, cooldowns, counts, and press feedback. Add a profile-owned ElvUI mover, preview, icon size/spacing controls, and a HUD toggle. Preserve the confirmed vehicle key-routing behavior.

## Changes in 1.2.0

Make the HUD left-clickable in combat and add hover tooltips from ElvUI's source buttons. Use protected action buttons and secure vehicle/page transitions for layout; freeze ordinary layout changes during combat and compact afterward. Keep previews inert and retain the existing key remapping.

## Development and releases

See [RELEASING.md](RELEASING.md) for package previews, CurseForge/Wago setup, and tag-driven publishing. The addon uses the same custom license as Cooldown Companion; see [LICENSE.txt](LICENSE.txt).
