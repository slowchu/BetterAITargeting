# BetterAITargeting

Lua-only OpenMW 0.49/0.50 mod that reduces enemy player-tunneling by periodically retargeting hostile actors from the player to the nearest valid nearby player-side defender (followers/escorts/helpers), using only documented Lua APIs.

## Architecture

- **Script registration** is handled by `BetterAITargeting.omwscripts`, attaching:
  - `global.lua` + `settings.lua` as global scripts.
  - `enemy_local.lua` and `defender_local.lua` to `NPC` and `CREATURE`.
- **Local scripts and nearby visibility**:
  - `enemy_local.lua` and `defender_local.lua` run as local scripts, so they can use `openmw.nearby` for nearby active objects/cells.
  - They only modify `self` (enemy AI package state for `enemy_local.lua`; registry membership events for `defender_local.lua`).
- **Global coordination**:
  - `defender_local.lua` reports register/unregister through `core.sendGlobalEvent`.
  - `global.lua` owns registry writes in `openmw.storage.globalSection(...)` and sets lifetime to `Temporary`.
  - Registry mutation uses `getCopy(...)` before `set(...)`.
- **Enemy retarget logic** (`enemy_local.lua`):
  - Runs in `onUpdate(dt)` pulse.
  - Reads active combat target with `interfaces.AI.getActiveTarget('Combat')`.
  - Only overrides when current active target is the player.
  - Selects nearest valid registered defender by squared distance (`(a.position - b.position):length2()`) within radius.
  - Optional LOS check uses `nearby.castRay(..., { radius = 0 })` sparingly.
  - Anti-thrash: pulse interval + cooldown + no-op if already on selected target.
- **Combat package normalization (critical)**:
  - On retarget: `AI.removePackages('Combat')` then `AI.startPackage({ type='Combat', target=best })`.
  - This intentionally normalizes only Combat packages and preserves non-Combat package types.
- **Defender classification** (`defender_local.lua`, conservative v1):
  - Active `Follow`/`Escort` targeting player.
  - Any package with `sideWithTarget = true` and `target = player`.
  - No fake summon API, no undocumented hostility inference.

## File layout

```text
BetterAITargeting/
  BetterAITargeting.omwscripts
  scripts/
    YourName/
      BetterAITargeting/
        enemy_local.lua
        defender_local.lua
        global.lua
        shared.lua
        settings.lua
  l10n/
    en.yaml
  README.md
```

## Installation

1. Copy `BetterAITargeting/` into your OpenMW data path.
2. Enable `BetterAITargeting.omwscripts` in the OpenMW launcher (or add it to openmw.cfg content list).
3. Launch the game and open Mod Settings to tune options:
   - enabled
   - pulseSeconds
   - scanRadius
   - useLineOfSight
   - retargetCooldownSeconds
   - debugLogging

## Testing (manual, in-game)

1. Spawn/bring at least one follower or escort-style ally.
2. Enter combat with one or more hostile NPC/creatures.
3. Confirm hostiles initially targeting player can switch to helper when helper is nearby.
4. Toggle LOS option and verify retarget frequency changes around obstacles.
5. Enable debug logging and inspect log output for:
   - active target checks
   - defender counts
   - LOS rejections
   - retarget decisions
   - combat package normalization messages

## Why this design matches OpenMW constraints

- Uses local scripts for nearby queries and per-actor logic.
- Uses global script for writable shared registry state.
- Uses global events for local→global communication.
- Uses documented AI package APIs and package fields.
- Uses documented storage lifetime and `getCopy` mutation rule.
- Keeps v1 as a narrow override layer rather than recreating hidden engine heuristics.

## Known limitations

- There is no universal documented Lua hostility query used here; “hostile” is inferred conservatively by “actor currently has active Combat target = player”.
- Summon detection is not hard-coded with undocumented APIs; summon-like support is only recognized via documented package relations.
- Reachability/path quality and deep internal action-rating checks are not replicated; optional LOS is the only cheap visibility filter.
- Registry is runtime-only (`Temporary`) and intentionally not persisted across saves/reloads.

## OpenMW documentation references used

- Overview (script contexts, global/local model):
  - https://openmw.readthedocs.io/en/openmw-0.49.0/reference/lua-scripting/overview.html
- Engine handlers (`onUpdate`, `onInactive`, local/global handler scopes):
  - https://openmw.readthedocs.io/en/openmw-0.49.0/reference/lua-scripting/engine_handlers.html
- AI interface (`getActiveTarget`, `getActivePackage`, `forEachPackage`, `removePackages`, `startPackage`, package fields):
  - https://openmw.readthedocs.io/en/openmw-0.49.0/reference/lua-scripting/interface_ai.html
- Built-in AI package schema/examples (`Combat`, `Follow`, `Escort`, `StartAIPackage` event pattern):
  - https://openmw.readthedocs.io/en/openmw-0.49.0/reference/lua-scripting/aipackages.html
- Nearby API (`nearby.actors`, `nearby.players`, `castRay`, local-only constraints):
  - https://openmw.readthedocs.io/en/openmw-0.49.0/reference/lua-scripting/openmw_nearby.html
- Self object (local self access):
  - https://openmw.readthedocs.io/en/openmw-0.49.0/reference/lua-scripting/openmw_self.html
- Util vectors (`Vector3` arithmetic and length/length2):
  - https://openmw.readthedocs.io/en/openmw-0.49.0/reference/lua-scripting/openmw_util.html
- Storage (`globalSection`, lifetime, `get`/`getCopy` semantics):
  - https://openmw.readthedocs.io/en/openmw-0.49.0/reference/lua-scripting/openmw_storage.html
- Settings interface:
  - https://openmw.readthedocs.io/en/openmw-0.49.0/reference/lua-scripting/interface_settings.html
- Setting renderer keys (`checkbox`, `number`):
  - https://openmw.readthedocs.io/en/openmw-0.49.0/reference/lua-scripting/setting_renderers.html
- Core global events (`core.sendGlobalEvent`):
  - https://openmw.readthedocs.io/en/openmw-0.49.0/reference/lua-scripting/openmw_core.html
- Clarifying interface index/latest docs:
  - https://openmw.readthedocs.io/en/latest/reference/lua-scripting/index_interfaces.html
  - https://openmw.readthedocs.io/en/latest/reference/lua-scripting/interface_settings.html
  - https://openmw.readthedocs.io/en/stable/reference/lua-scripting/overview.html
