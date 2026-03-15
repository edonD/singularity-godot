# Singularity Survivor V2 — Godot 4.4

A 16-bit pixel art survival game built in Godot 4.4 with GDScript. Fight against NEXUS, a superintelligence that consumed civilization. Explore, craft, survive, make impossible choices, and discover the truth.

## V2 — What's New

V2 transforms Singularity Survivor from a solid action game into a deep, systems-driven survival RPG with moral weight. Every system interconnects. Your choices matter.

### Character Depth
- **Skill Tree**: 3 branches (Combat, Stealth, Tech) with 9 skills each (27 total). Skills genuinely change gameplay — Berserker Rage, Camouflage, Turret Deployment, NEXUS Mimicry, and more
- **Character Backgrounds**: Choose Soldier, Scientist, or Survivalist at game start. Each has different stats and unlocks different dialogue options
- **Emotional State**: Fear, determination, despair, hope — affected by events, influences combat modifiers, dialogue options, and some abilities
- **Morality Tracking**: Not good/evil — pragmatic, compassionate, or ruthless. Your choices are tracked and affect NPC reactions

### Life Dilemmas
- 6 moral dilemmas that appear organically: dying survivor begging for your medkit, NEXUS data terminal (intel vs. being tracked), child hiding alone, captured experiment subject, shelter discovered by NEXUS, outpost raid invitation
- Choices affect: inventory, emotions, morality, NEXUS awareness, available missions, and endings
- Dramatic UI presentation with branching consequences

### Survival Systems
- **Temperature**: Cold at night/mountains, need fire/clothing. Freezing causes damage and frostbite
- **Injuries**: Bleeding, broken limbs, infections, burns, frostbite — each with severity levels and timed duration
- **Sleep Deprivation**: Performance degrades, hallucinations at extreme levels, collapse at zero
- **Food Spoilage**: Cooked meat decays over time — manage inventory timing

### Dialogue & Story
- Branching dialogue system with NPC portraits and typewriter text effect
- 3 full dialogue trees with emotion-gated, morality-gated, and skill-gated choices
- Choices unlock missions, give items, and affect emotional state
- Quest journal with 10 quests (6 main, 4 side), tracked objectives, and lore collection

### World
- **Points of Interest**: 8 POI types spawning dynamically — crashed helicopters, bridges, tunnels, radio towers, NEXUS wreckage, frozen ponds
- **Environmental Puzzles**: 5 types — power redirect, water drain, radio repair, door hack, generator fix. Multi-step solving with material costs
- **World Map**: Fog of war exploration, player marker, POI markers, biome colors. Press M to view

### NEXUS Adaptive Difficulty
- NEXUS tracks your playstyle: stealth → thermal sensors, combat → sentinels, hoarding → harvesters
- 10-tier escalation: Scout Phase → SINGULARITY PROTOCOL
- Dynamic events: supply drops, patrol sweeps, survivor distress calls, EMP storms
- Enemies scale with threat level (HP, damage, detection range)

### UI Improvements
- **Character Sheet** (C): Full stats, emotions, morality, injuries, survival status, NEXUS awareness, dilemma history
- **Skill Tree** (T): Visual tree with 3 branch tabs, unlock skills with points
- **Quest Journal** (J): Active/completed quests with objectives, lore tab
- **World Map** (M): Fog of war, explored terrain, POI markers

## Current State

**V2 complete — 70+ features, 66 script files, ~10,500 lines of code.**

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
| **Temperature System (cold/heat, frostbite)** | **V2** |
| **Injury System (bleeding, broken limb, infection, burn)** | **V2** |
| **Sleep Deprivation (hallucinations, collapse)** | **V2** |
| **Food Spoilage** | **V2** |
| HUD (HP/Stamina/XP/Hunger/Thirst/Temp/Sleep, minimap) | Done |
| 3 Player Abilities (EMP, Cloak, Shield) | Done |
| **Skill Tree (27 skills, 3 branches)** | **V2** |
| **Character Backgrounds (Soldier/Scientist/Survivalist)** | **V2** |
| **Emotional State (fear/determination/despair/hope)** | **V2** |
| **Life Dilemmas (6 moral choices with consequences)** | **V2** |
| **Branching Dialogue System (3 NPC trees, portraits)** | **V2** |
| **Quest Journal (10 quests, lore collection)** | **V2** |
| **Character Sheet (full stat display)** | **V2** |
| **World Map (fog of war, POI markers)** | **V2** |
| **NEXUS AI Director (adaptive difficulty, escalation)** | **V2** |
| **Points of Interest (8 types, dynamic spawning)** | **V2** |
| **Environmental Puzzles (5 types, multi-step)** | **V2** |
| **Morality Tracking (pragmatic/compassionate/ruthless)** | **V2** |
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
| Status Effects (poison, slow, stun) | Done |
| Combo Counter (3x→10x tracking) | Done |
| Campfires (rest points, HP regen) | Done |
| Loot Crates (breakable containers) | Done |
| NPC Survivors (dialogue, rewards) | Done |
| Weather System (rain, snow, fog, storm) | Done |
| Environmental Hazards (toxic, electric, NEXUS) | Done |
| Resource Nodes (berry, scrap, crystal) | Done |
| Difficulty Scaling Indicator | Done |
| Finisher Combo (3rd hit slam) | Done |
| **Shelter Building (walls, doors, workbench, storage)** | **V2** |
| **Dynamic World Events (supply drops, patrols, distress)** | **V2** |
| **Medicine System (antibiotics, splints, burn cream)** | **V2** |
| **Dynamic Player Appearance (background + equipment)** | **V2** |

## How to Play

### Controls
| Key | Action |
|-----|--------|
| **WASD** | Move (8-directional) |
| **Left Shift** | Sprint (costs stamina) |
| **Left Click** | Melee attack (3-hit combo) |
| **Right Click** | Shoot arrow (requires arrows) |
| **Space** | Dodge roll (i-frames) |
| **E** | Interact (terminals, NPCs, puzzles, POIs) |
| **I** | Inventory / Crafting |
| **T** | Skill Tree |
| **J** | Quest Journal |
| **C** | Character Sheet |
| **M** | World Map |
| **B** | Build Mode (shelter construction) |
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

## Skill Tree

### Combat Branch (9 skills)
| Skill | Cost | Effect |
|-------|------|--------|
| Power Strike | 1 | +20% melee damage |
| Berserker Rage | 2 | Below 30% HP: +50% attack speed/damage |
| Shield Bash | 1 | Dodge into enemies to stun 1.5s |
| Counter-Attack | 2 | Perfect dodge triggers free 2x damage hit |
| Dual Wield | 2 | Combo hits twice per swing |
| Execute | 3 | Instant kill enemies below 10% HP |
| Thick Skin | 1 | +5 defense, +25 max HP |
| War Cry | 2 | Frighten enemies, -30% their damage 8s |
| Bloodlust | 3 | Each kill heals 10 HP, +5% attack 10s |

### Stealth Branch (9 skills)
| Skill | Cost | Effect |
|-------|------|--------|
| Silent Movement | 1 | Enemy detection range -30% |
| Backstab | 2 | 3x damage to unaware enemies |
| Distraction Throw | 1 | Throw noise maker to lure enemies |
| Camouflage | 2 | Stand still 2s to become invisible |
| Pickpocket | 2 | Steal components from unaware enemies |
| Runner | 1 | +25% sprint speed, +15% dodge distance |
| Night Owl | 2 | Night bonuses: +20% speed, +15% crit |
| Shadow Strike | 3 | 5x damage from camouflage, stuns 3s |
| Ghost | 3 | Dodge leaves afterimage enemies attack |

### Tech Branch (9 skills)
| Skill | Cost | Effect |
|-------|------|--------|
| Scanner | 1 | Reveal enemies/items on minimap |
| Turret Deployment | 2 | Place auto-turret (30s, 10 dmg/shot) |
| EMP Upgrade | 2 | +50% range, +2s stun, damages machines |
| Drone Hijacking | 2 | Convert stunned drones to allies 60s |
| NEXUS Mimicry | 3 | Disguise as NEXUS unit 15s |
| Scavenger | 1 | +50% enemy loot, double crate items |
| Field Repair | 2 | -25% craft cost, craft without workbench |
| Overcharge | 2 | -30% tech ability cooldowns |
| Singularity Core | 3 | Gravity well pulling and damaging enemies |

## Character Backgrounds

| Background | Bonuses | Playstyle |
|-----------|---------|-----------|
| **Soldier** | +5 ATK, +3 DEF, +20 HP | Combat-focused, tanky |
| **Scientist** | +10% Crit, +20 Stamina | Technical, analytical |
| **Survivalist** | +30 Hunger/Thirst, +15 Speed | Endurance, exploration |

## Life Dilemmas

| Dilemma | When | Choices |
|---------|------|---------|
| A Dying Stranger | Has bandage | Give medkit / Keep it / Take their supplies |
| NEXUS Data Terminal | Day 2+ | Download (tracked) / Destroy (safe) |
| Strength in Numbers | Day 5+ | Join raid / Refuse (they die) |
| A Child Alone | Day 3+ | Take with you (slow + food) / Give directions |
| What Remains | Day 7+ | Free hybrid / Leave them / Destroy pod |
| They Found You | Day 10+ | Fight the wave / Abandon shelter |

## Architecture

```
scenes/
  main/Main.tscn            # Game world, all systems wired together
  player/Player.tscn         # CharacterBody2D with combat
  enemies/                   # ScoutDrone, PatrolBot, Harvester, MindProbe, Sentinel
  ui/                        # HUD, Inventory, PauseMenu, TitleScreen, DeathScreen
                             # BackgroundSelect, SkillTreeUI, JournalUI, CharacterSheet
                             # WorldMapUI, DilemmaUI, DialogueUI
  world/                     # Terminal, NPC, Campfire, LootCrate, EnvHazard, ResourceNode, EnvPuzzle
  items/ItemDrop.tscn        # Pickup items with bob animation
  effects/Projectile.tscn    # Arrow/enemy projectiles

scripts/
  autoload/                  # GameManager, AudioManager, CameraManager, SaveManager
  player/                    # Player controller, abilities, sprite generation
  enemies/                   # EnemyBase + 5 enemy types
  systems/                   # Inventory, Crafting, WorldGen, Spawners, Missions, Weather
                             # SkillTree, EmotionalState, DilemmaSystem, DialogueSystem
                             # QuestJournal, NEXUSDirector, POISystem, EnvPuzzle, Survival
  ui/                        # All UI controllers
  effects/                   # Dust particles, Hit flash, Attack trail, Screen effects
```

## Tech

- **Engine**: Godot 4.4.1
- **Language**: GDScript — 66 files, ~10,500 lines, no script over 400 lines
- **Resolution**: 480x270 (16:9, 2x scaled to 960x540)
- **Physics**: CharacterBody2D with 6 collision layers
- **World**: Procedural TileMapLayer with FastNoiseLite (chunk-based)
- **Audio**: Procedural WAV generation (AudioStreamWAV, 22050Hz)
- **Weather**: Dynamic rain/snow/fog/storm with particle rendering
- **All art**: Generated programmatically — zero external assets
- **Signals**: Decoupled event system throughout
- **V2 Systems**: Skill tree, emotional state, dilemmas, dialogue, NEXUS AI director, POIs, puzzles, world map, shelter building, dynamic events, medicine, equipment visuals
- **70+ features**: See system status table above
