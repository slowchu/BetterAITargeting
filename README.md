# BetterAITargeting

Lua-only OpenMW 0.49/0.50 mod that reduces enemy player-tunneling by periodically retargeting hostile actors from the player to nearby valid player-side defenders (followers/escorts/helpers), using only documented APIs.

## Architecture

- **Registration via `.omwscripts`** with one script per line and `<flags>: <path>` format.
- **Local scripts** (`enemy_local.lua`, `defender_local.lua`) use nearby state and only mutate self/local decisions.
- **Global script** (`global.lua`) owns writable registry state in global storage and receives local->global events via `core.sendGlobalEvent`.
- **Runtime registry** is stored in `storage.globalSection('BetterAITargeting_Runtime')`, explicitly marked `Temporary`, and mutated using `getCopy(...)`.
- **Enemy retargeting** (`enemy_local.lua`):
  - runs on pulse from `onUpdate(dt)`.
  - checks active combat target with `AI.getActiveTarget('Combat')`.
  - only applies override when active combat target is player.
  - picks nearest registered nearby defender by squared distance (`Vector3:length2()`).
  - optional LOS check (`nearby.castRay`) with `radius = 0`.
  - anti-thrash via pulse + cooldown.
- **Combat package normalization**:
  - remove only combat packages (`AI.removePackages('Combat')`).
  - restart combat with `AI.startPackage({ type='Combat', target=best, cancelOther=false })` so non-combat packages are not canceled by default behavior.
- **Defender classification (conservative v1)** (`defender_local.lua`):
  - active Follow/Escort targeting player, or
  - any package with `sideWithTarget=true` and target player.

## File layout

```text
BetterAITargeting/
  BetterAITargeting.omwscripts
  scripts/
    BetterAITargeting/
        enemy_local.lua
        defender_local.lua
        global.lua
        shared.lua
        settings.lua
  l10n/
    BetterAITargeting/
        en.yaml
  README.md
```

## Installation

1. Copy `BetterAITargeting/` into your OpenMW data path.
2. Enable `BetterAITargeting.omwscripts` in OpenMW launcher.
3. Configure settings in Mod Settings page.

## Testing (manual)

1. Bring follower/escort helper.
2. Start combat with hostile enemies.
3. Verify enemies targeting player can retarget to registered helper in range.
4. Toggle LOS and compare behavior around obstacles.
5. Enable debug logging and confirm reasons/decisions in logs.

## Why this design matches OpenMW constraints

- Nearby scans are local-script only.
- Shared writable state is global-script only.
- Local->global communication uses documented global events.
- Settings use documented settings interface/renderers, with a compatibility fallback if `Settings.registerPage` is unavailable in a given runtime build/context.
- AI control uses documented package APIs; no undocumented hostility APIs.

## Known limitations

- Summons may be missed if they do not expose conservative package signals used by v1.
- No deep engine reachability/threat replication (intentional for maintainable Lua-only v1).
- Hostility inference is intentionally narrow: override only when current active combat target is player.

## OpenMW documentation references used

- Overview:
  - https://openmw.readthedocs.io/en/openmw-0.49.0/reference/lua-scripting/overview.html
- Engine handlers:
  - https://openmw.readthedocs.io/en/openmw-0.49.0/reference/lua-scripting/engine_handlers.html
- AI interface:
  - https://openmw.readthedocs.io/en/openmw-0.49.0/reference/lua-scripting/interface_ai.html
- AI packages:
  - https://openmw.readthedocs.io/en/openmw-0.49.0/reference/lua-scripting/aipackages.html
- Nearby API:
  - https://openmw.readthedocs.io/en/openmw-0.49.0/reference/lua-scripting/openmw_nearby.html
- Self API:
  - https://openmw.readthedocs.io/en/openmw-0.49.0/reference/lua-scripting/openmw_self.html
- Util vectors:
  - https://openmw.readthedocs.io/en/openmw-0.49.0/reference/lua-scripting/openmw_util.html
- Storage:
  - https://openmw.readthedocs.io/en/openmw-0.49.0/reference/lua-scripting/openmw_storage.html
- Settings interface:
  - https://openmw.readthedocs.io/en/openmw-0.49.0/reference/lua-scripting/interface_settings.html
- Setting renderers:
  - https://openmw.readthedocs.io/en/openmw-0.49.0/reference/lua-scripting/setting_renderers.html
- Core (`sendGlobalEvent`):
  - https://openmw.readthedocs.io/en/openmw-0.49.0/reference/lua-scripting/openmw_core.html
