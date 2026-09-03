# D: Rift Protocol

A playable Godot 4 combat sandbox for a data-driven 2D action RPG with a four-character realtime party. The project deliberately proves the hard foundation first: movement, collision, camera, independent party state, swap, hit detection, enemy AI, skills, ultimate energy, elemental reactions, and effects that survive a character swap.

## Play

Open the folder in **Godot 4.3+** and run `scenes/main.tscn` (F6) or the whole project (F5).

| Input | Action |
|---|---|
| `WASD` / arrows | Move in 8 directions |
| Left mouse | Basic attack |
| `E` | Character skill |
| `Q` | Ultimate at 100% energy |
| `1`–`4` | Realtime party swap |
| `R` | Restart the combat cell |

## Playable party

| Slot | Character | Role | Skill |
|---|---|---|---|
| 1 | Ember | Fire DPS | Places an **off-field sentry** that persists and fires after swapping |
| 2 | Volt | Fast burst DPS | Fires a high-damage Arc Lance projectile |
| 3 | Tide | Sustain | Heals the active character and damages nearby enemies |
| 4 | Terra | Tank / AoE | Creates a heavy radial Fault Line |

Hit an infused enemy with another element to trigger a **Rift Reaction**. The clean test combo is `1 → E → 2 → attacks/E`: Ember's sentry remains in the world while Volt becomes active.

## Architecture

```text
CharacterData (.tres)       Static design data
        ↓
CharacterRuntime            Per-slot HP, energy, cooldown
        ↓
PartyManager                Owns four runtime states + swap rules
        ↓
PlayerCharacter             One generic controller / hitbox / hurtbox

World-owned combat effects  Turrets and projectiles survive swaps
```

Important folders:

```text
data/characters/            Character resources; tune without controller edits
src/core/                   Character data, runtime state, party manager
src/actors/                 Generic player and enemy actors
src/combat/                 Projectile, turret, rings, combat text
src/world/                  Greybox combat arena and collision
src/ui/                     Realtime HUD and party cards
tests/                      Headless architecture smoke test
```

No character-specific controller scripts exist. New characters are added as `CharacterData` resources plus a skill implementation, while shared movement, damage, animation hooks, hitbox, hurtbox, camera, and state logic stay generic.

## Headless test

```bash
godot --headless --path . --script res://tests/test_runner.gd
```

GitHub Actions runs the same smoke test on every push and pull request.

## Scope

This repository is the first vertical slice, not a fake “full gacha game” shell. Story, banners, inventory, real maps, production sprites, quests, and monetization are intentionally excluded until the combat loop is fun and the party architecture is stable.
