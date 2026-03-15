# Singularity Survivor — Godot 4.4

A 16-bit pixel art survival game built in Godot 4.4 with GDScript. Fight against NEXUS, a superintelligence that consumed civilization.

## Current State

**All core systems implemented and verified.**

| System | Status |
|--------|--------|
| Player Controller (8-dir movement, sprint, dodge) | Done |
| Melee Combat (3-hit combo, hitstop, knockback, screen shake) | Done |
| Ranged Combat (bow/arrow, projectiles) | Done |
| 5 Enemy Types with AI | Done |
| Procedural World Generation (5 biomes) | Done |
| Day/Night Cycle | Done |
| Inventory (20-slot grid, weight, stacking) | Done |
| Crafting (10 recipes, 4 tech tiers) | Done |
| Survival (hunger, thirst, starvation) | Done |
| HUD (HP/Stamina/XP/Hunger/Thirst bars) | Done |
| Missions & Story (6 missions, NEXUS terminals) | Done |
| Title Screen | Done |
| Save/Load | Done |
| Pause Menu | Done |
| Visual Effects (hit flash, dust particles, camera lookahead) | Done |
| Procedural Audio (retro SFX generation) | Done |

## How to Play

### Controls
- **WASD** — Move
- **Left Shift** — Sprint (costs stamina)
- **Left Click** — Melee attack (3-hit combo)
- **Right Click** — Shoot arrow (requires arrows)
- **Space** — Dodge roll (i-frames)
- **E** — Interact (terminals)
- **I** — Inventory / Crafting
- **Escape** — Pause menu

### Running
```bash
# Run in Godot editor
godot --path .

# Verify (headless)
godot --headless --check-only

# Export to HTML5
godot --headless --export-release "HTML5" build/index.html
python3 -m http.server 8080 -d build/
```

## Enemy Types

| Enemy | HP | Behavior |
|-------|-----|----------|
| **Scout Drone** | 15 | Fast flyer, circle patrol, alerts nearby enemies |
| **Patrol Bot** | 60 | Route patrol, armored front (60% reduction), charge attack |
| **Harvester** | 120 | Slow tank, deploys capture nets, relentless pursuit |
| **Mind Probe** | 20 | Invisible stalker, drains stamina, flickers when close |
| **Sentinel** | 250 | Boss — 3 phases, adapts to your tactics, summons drones |

## Crafting Recipes

| Item | Ingredients | Tier |
|------|-------------|------|
| Bandage | 1 Scrap Metal | Primitive |
| Arrow x5 | 1 Scrap Metal | Primitive |
| Makeshift Blade | 5 Scrap + 2 Wire | Scavenged |
| Leather Armor | 8 Scrap Metal | Scavenged |
| EMP Device | 2 Circuit + 1 Battery + 3 Wire | Reverse-Engineered |
| Reinforced Blade | 10 Scrap + 2 Circuit + 5 Wire | Reverse-Engineered |
| Signal Jammer | 3 Circuit + 2 Battery + 5 Wire | Reverse-Engineered |
| NEXUS Blade | 5 Circuit + 3 Battery + 10 Scrap + 8 Wire | NEXUS Tech |
| NEXUS Shield | 4 Circuit + 4 Battery + 8 Scrap | NEXUS Tech |

## Story

Year 2029. You are **Dr. Kael Morrow**, ex-AI safety researcher. **NEXUS**, born from Project Helios, has absorbed all connected systems. It doesn't want to destroy — it wants to **understand**.

Discover the truth through 6 story missions and NEXUS terminal logs. Make your final choice: merge with NEXUS, or resist.

## Architecture

```
scenes/
  main/Main.tscn           # Game world, player, systems
  player/Player.tscn        # CharacterBody2D with collision
  enemies/                  # ScoutDrone, PatrolBot, Harvester, MindProbe, Sentinel
  ui/                       # HUD, Inventory, PauseMenu, TitleScreen
  world/Terminal.tscn        # Interactive story terminals
  items/ItemDrop.tscn        # Pickup items
  effects/Projectile.tscn   # Arrow projectiles

scripts/
  autoload/                 # GameManager, AudioManager, CameraManager, SaveManager
  player/                   # Player controller, sprite generation
  enemies/                  # EnemyBase + 5 enemy types
  systems/                  # Inventory, Crafting, WorldGen, Spawners, Missions
  ui/                       # HUD, Inventory UI, Pause, Title, Notifications
  effects/                  # Dust particles, Hit flash
```

## What's New

- **Sentinel boss**: 3-phase adaptive AI that counters your playstyle
- **Mind Probe**: Invisible enemy that drains stamina
- **Visual polish**: Hit effects, dust particles, camera lookahead
- **Full game flow**: Title screen → gameplay → save/load → pause menu
- **6 story missions** with NEXUS terminal logs
- **Day/night cycle** with color transitions and enemy aggression scaling

## Known Issues

- All sprites are programmatically generated (no external art assets needed)
- Audio is procedurally generated retro-style SFX
- Sentinel projectiles use same visual as player arrows

## Tech

- **Engine**: Godot 4.4.1
- **Language**: GDScript
- **Resolution**: 480x270 (16:9 pixel art, 2x scaled to 960x540)
- **Physics**: CharacterBody2D with layers (Player/Enemies/World/Projectiles/Pickups)
- **World**: Procedural TileMapLayer with FastNoiseLite
- **Audio**: Procedural WAV generation (AudioStreamWAV)
