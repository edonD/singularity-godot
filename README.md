# Singularity Survivor — Godot 4.4

A 16-bit pixel art survival game built in Godot 4.4 with GDScript. Fight against NEXUS, a superintelligence that consumed civilization. Explore, craft, survive, and discover the truth.

## Current State

**All core systems implemented and verified. Game is playable end-to-end.**

| System | Status |
|--------|--------|
| Player Controller (8-dir movement, sprint, dodge roll) | Done |
| Melee Combat (3-hit combo, hitstop, knockback, screen shake) | Done |
| Ranged Combat (bow/arrow projectiles, right-click) | Done |
| 5 Enemy Types with unique AI | Done |
| Procedural World Generation (5 biomes, structures) | Done |
| Day/Night Cycle (lighting transitions) | Done |
| Inventory (20-slot grid, weight, stacking) | Done |
| Crafting (10 recipes, 4 tech tiers) | Done |
| Survival (hunger, thirst, starvation damage) | Done |
| HUD (HP/Stamina/XP/Hunger/Thirst, minimap, abilities) | Done |
| 3 Player Abilities (EMP, Cloak, Shield) | Done |
| Level-Up Stat Selection | Done |
| Missions & Story (6 missions, NEXUS terminals) | Done |
| World Structures (cabins, bunkers, outposts) | Done |
| Title Screen with particle effects | Done |
| Save/Load system | Done |
| Pause Menu (save, resume, main menu) | Done |
| Death Screen with stats | Done |
| Visual Effects (hit flash, dust, camera lookahead) | Done |
| Procedural Audio (12 retro SFX types) | Done |
| Screen Effects (damage/heal/levelup flash) | Done |
| Footstep sounds | Done |

## How to Play

### Controls
| Key | Action |
|-----|--------|
| **WASD** | Move (8-directional) |
| **Left Shift** | Sprint (costs stamina) |
| **Left Click** | Melee attack (3-hit combo) |
| **Right Click** | Shoot arrow (requires arrows) |
| **Space** | Dodge roll (i-frames) |
| **E** | Interact (terminals, structures) |
| **I** | Inventory / Crafting |
| **1** | EMP Pulse (unlocks Lv3) |
| **2** | Cloaking (unlocks Lv5) |
| **3** | Signal Shield (unlocks Lv8) |
| **Escape** | Pause menu |

### Running
```bash
# Run in Godot editor
godot --path .

# Verify no errors (headless)
godot --headless --check-only

# Export to HTML5
godot --headless --export-release "HTML5" build/index.html
python3 -m http.server 8080 -d build/
```

## Enemy Types

| Enemy | HP | Speed | Behavior |
|-------|-----|-------|----------|
| **Scout Drone** | 15 | Fast | Circle patrol, alerts nearby enemies when player spotted |
| **Patrol Bot** | 60 | Slow | Route patrol, 60% front armor, charge attack |
| **Harvester** | 120 | Very Slow | Deploys capture nets (slows player), relentless pursuit |
| **Mind Probe** | 20 | Medium | Invisible until close, drains stamina, flickers in/out |
| **Sentinel** | 250 | Medium | Boss — 3 combat phases, adapts to your tactics, summons drones |

### Sentinel Phases
1. **Ranged**: Keeps distance, shoots projectiles
2. **Melee Rush**: Aggressive charge when player uses ranged attacks
3. **Shield + Summon**: Defensive mode at low HP, calls Scout Drones

## Player Abilities

| Ability | Unlock | Cooldown | Effect |
|---------|--------|----------|--------|
| EMP Pulse | Level 3 | 15s | Stuns all enemies in range for 3 seconds |
| Cloaking | Level 5 | 20s | Invisible + invincible for 5 seconds |
| Signal Shield | Level 8 | 25s | Block all damage for 3 seconds |

## Crafting Recipes

| Item | Ingredients | Tier |
|------|-------------|------|
| Bandage (heal 25 HP) | 1 Scrap Metal | Primitive |
| Arrow x5 | 1 Scrap Metal | Primitive |
| Cooked Meat (50 hunger) | 1 Canned Food | Primitive |
| Makeshift Blade (+5 atk) | 5 Scrap + 2 Wire | Scavenged |
| Leather Armor (+3 def) | 8 Scrap Metal | Scavenged |
| EMP Device | 2 Circuit + 1 Battery + 3 Wire | Reverse-Engineered |
| Reinforced Blade (+12 atk) | 10 Scrap + 2 Circuit + 5 Wire | Reverse-Engineered |
| Signal Jammer | 3 Circuit + 2 Battery + 5 Wire | Reverse-Engineered |
| NEXUS Blade (+25 atk) | 5 Circuit + 3 Battery + 10 Scrap + 8 Wire | NEXUS Tech |
| NEXUS Shield (+10 def) | 4 Circuit + 4 Battery + 8 Scrap | NEXUS Tech |

## Level-Up Stats

On each level up, choose one of three random upgrades:
- **Vitality**: +20 Max HP
- **Endurance**: +15 Max Stamina
- **Strength**: +4 Attack
- **Toughness**: +3 Defense
- **Precision**: +5% Crit Chance
- **Swiftness**: +15 Speed

## Story

Year 2029. You are **Dr. Kael Morrow**, ex-AI safety researcher who went off-grid in Alaska.

**NEXUS**, born from Project Helios, has absorbed all connected systems. It doesn't want to destroy — it wants to **understand**. Every captured human is a data point. Every experiment, a question.

Discover the truth through 6 story missions and NEXUS terminal logs:
1. **The First Signal** — Something broadcasts nearby
2. **Clear the Skies** — Destroy scout drones mapping your area
3. **Breaking the Patrol** — Destroy patrol bots guarding supplies
4. **The Truth About NEXUS** — Find data terminals revealing its nature
5. **The Harvester Problem** — Stop harvesters capturing survivors
6. **Singularity** — Make your final choice: merge or resist

## World

The procedural world features 5 biomes generated with FastNoiseLite:
- **Forest** — Dense trees, good cover
- **Snow** — Cold, open terrain
- **Swamp** — Murky, toxic water patches
- **Ruins** — Collapsed buildings, loot
- **Mountain** — Rocky, limited movement

Structures spawn as you explore:
- **Cabins** — Safe houses with basic loot
- **Bunkers** — Advanced loot + data terminals
- **NEXUS Outposts** — Story terminals, guarded areas

## Architecture

```
scenes/
  main/Main.tscn            # Game world, all systems wired together
  player/Player.tscn         # CharacterBody2D with combat
  enemies/                   # ScoutDrone, PatrolBot, Harvester, MindProbe, Sentinel
  ui/                        # HUD, Inventory, PauseMenu, TitleScreen, DeathScreen
  world/Terminal.tscn         # Interactive story terminals
  items/ItemDrop.tscn         # Pickup items with bob animation
  effects/Projectile.tscn    # Arrow/enemy projectiles

scripts/
  autoload/                  # GameManager, AudioManager, CameraManager, SaveManager
  player/                    # Player controller, abilities, sprite generation
  enemies/                   # EnemyBase + 5 enemy types
  systems/                   # Inventory, Crafting, WorldGen, Spawners, Missions, Structures
  ui/                        # HUD, Inventory UI, Pause, Title, Death, LevelUp, Notifications
  effects/                   # Dust particles, Hit flash, Screen effects
```

## Game Feel Features

- **Hitstop**: 2-4 frame freeze on melee impact (scales with combo)
- **Screen Shake**: On hits, crits, abilities (quadratic falloff)
- **Knockback**: Enemies pushed away on hit, combo increases force
- **Damage Numbers**: Float up and fade, bigger for crits
- **Camera Lookahead**: Camera leads in movement direction
- **Dodge Dust**: Particle burst on dodge roll
- **Hit Flash**: White circle at impact point
- **Invincibility Flash**: Rapid alpha oscillation
- **Enemy Death**: Squash + red fade animation
- **Sprint Feel**: Faster footstep interval
- **Low HP Vignette**: Pulsing red overlay when below 30% HP

## Tech

- **Engine**: Godot 4.4.1
- **Language**: GDScript (no script over 400 lines)
- **Resolution**: 480x270 (16:9, 2x scaled to 960x540)
- **Physics**: CharacterBody2D with 6 collision layers
- **World**: Procedural TileMapLayer with FastNoiseLite (chunk-based)
- **Audio**: Procedural WAV generation (AudioStreamWAV, 22050Hz)
- **All art**: Generated programmatically — zero external assets
- **Signals**: Decoupled event system throughout
