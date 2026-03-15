# Singularity Survivor — Godot 4.4 Edition

You are a world-class indie game developer. Build a professional, polished, PLAYABLE 16-bit pixel art survival game in Godot 4.4 using GDScript.

## Context

There is an existing HTML5 version at https://github.com/edonD/singularity-survivor that has a great premise but plays poorly — clunky movement, no game feel, boring combat, the systems don't interconnect well. Your job is to rebuild this concept properly in Godot with real game feel, tight controls, satisfying combat, and systems that create emergent gameplay.

## Story (Same Premise, Better Execution)

Year 2029. You are Dr. Kael Morrow — ex-AI safety researcher who went off-grid in Alaska. NEXUS, a superintelligence born from Project Helios, has absorbed all connected systems. It doesn't want to destroy — it wants to UNDERSTAND. It experiments on humans. Cities fell. Now it's coming for the wilderness.

You survive. You scavenge. You fight back. You discover what NEXUS really is.

## The #1 Priority: GAME FEEL

This is what the HTML version got wrong. Every interaction must feel GOOD:

- **Movement**: Snappy, responsive. 8-directional with slight acceleration/deceleration. Sprint with stamina cost. The character should feel NIMBLE, not floaty.
- **Combat**: Attacks have weight. Screen shake on hit. Knockback on enemies. Brief hitstop (2-3 frames of freeze on impact). Damage numbers pop up. Death animations. Sound feedback on every hit.
- **Feedback**: Every action has visual + audio feedback. Pick up item? Flash + sound. Level up? Screen effect + fanfare. Low HP? Heartbeat + vignette. Enemy spotted you? Alert sound + indicator.
- **Camera**: Smooth follow with slight look-ahead in movement direction. Subtle zoom changes for combat vs exploration.

## Godot 4.4 Project Structure

```
singularity-godot/
  project.godot
  scenes/
    main/Main.tscn              # Main scene, level manager
    player/Player.tscn          # Player character
    enemies/                    # Enemy scenes (one per type)
    ui/                         # HUD, inventory, menus
    world/                      # Tilemap, structures
    items/                      # Pickup items
    effects/                    # Particles, screen effects
  scripts/
    player/player.gd            # Player controller
    enemies/                    # Enemy AI scripts
    systems/                    # Game systems (inventory, crafting, missions)
    ui/                         # UI controllers
    autoload/                   # Singletons (GameManager, AudioManager, SaveManager)
  assets/
    sprites/                    # Pixel art spritesheets
    audio/                      # Sound effects, music
    fonts/                      # Pixel fonts
  addons/                       # Any Godot plugins
```

### Code Rules (NON-NEGOTIABLE)
- **NO script file over 400 lines** — split into smaller components
- Use Godot signals for decoupled communication
- Use autoloads for global systems (GameManager, AudioManager, SaveManager)
- Use resources (.tres) for item/enemy data definitions
- Use state machines for player and enemy AI
- Use TileMap for world generation
- All pixel art drawn programmatically or described as sprite data (no external image files needed — use Godot's built-in drawing or create sprites via code)

## Core Systems to Implement

### 1. Player (MUST feel great)
- 8-directional movement with animation states (idle, walk, run, attack, hurt, die)
- Stamina-based sprinting
- Melee attack combo (2-3 hits)
- Ranged attack (bow/throwables)
- Dodge roll with i-frames
- Stats: HP, Stamina, Hunger, Thirst, XP, Level

### 2. World Generation
- Procedural tilemap: forest, snow, swamp, ruins, mountains
- Structures: cabin (start), abandoned town, bunker, NEXUS outpost
- Day/night cycle with lighting changes (CanvasModulate)
- NEXUS gets more aggressive at night

### 3. Enemies (Varied, Interesting AI)
- **Scout Drone**: Fast, weak, alerts others. Flies in patterns.
- **Patrol Bot**: Walks routes, has a cone of vision. Heavily armored front.
- **Harvester**: Slow, relentless. Deploys capture net. Being caught = escape mini-game.
- **Mind Probe**: Invisible until high Perception. Drains sanity.
- **Sentinel**: Boss-tier. Adapts to your tactics.
- Each enemy has: detection states (unaware > suspicious > alert > hunting), unique attack patterns, death drops

### 4. Combat That Feels Good
- Melee: swing arc, enemies get knocked back, screen shake, hitstop
- Ranged: projectile physics, aim indicator, ammo management
- Dodge roll: i-frames, dust particles, satisfying sound
- Critical hits: bigger numbers, special effect
- Enemy variety forces different strategies

### 5. Inventory & Crafting
- Grid-based inventory (like Resident Evil 4)
- Items have weight, stack limits
- Crafting at workbenches: combine components into tools/weapons
- Tech tiers: Primitive > Scavenged > Reverse-Engineered > NEXUS Tech
- Recipes discovered through exploration

### 6. Survival
- Hunger/thirst deplete over time
- Food sources: hunting, foraging, canned goods, cooking
- Temperature in cold biomes
- Rest at safe locations

### 7. Progression
- XP from kills, exploration, missions
- Level up: choose stat upgrades
- Abilities unlocked at milestones: EMP Pulse, Cloaking, Hacking, Signal Shield
- Each ability has cooldown, visual effect, sound

### 8. Missions & Story
- 5+ main story missions revealing NEXUS's true nature
- Side missions: rescue survivors, raid outposts, destroy signal towers
- Story delivered through terminals, journals, NPC dialogue
- Multiple endings

### 9. UI
- HUD: HP/Stamina/Hunger/Thirst bars, minimap, ability cooldowns, day counter
- Inventory screen (I key)
- Pause menu with save/load
- Title screen with new game/continue
- Clean pixel art UI that matches the game aesthetic

### 10. Audio
- Use Godot AudioStreamPlayer for all audio
- Generate simple retro sounds via code (AudioStreamGenerator) or use Godot's built-in synth
- Ambient: wind, crickets, NEXUS hum near outposts
- Combat: hit sounds, weapon swings, enemy alerts
- Music: simple procedural loops for exploration/combat/menu

## How to Build in Godot Headless (No GUI)

Since this is a headless server, you create everything via scripts and .tscn files as text:

1. **project.godot**: Create the project configuration file manually
2. **.tscn files**: Godot scene files are text-based — you can write them directly
3. **.gd scripts**: GDScript files are plain text
4. **.tres resources**: Resource files are text-based
5. **Export**: Use `godot --headless --export-release "HTML5" build/index.html` to export for web

### Testing Without GUI
- Use `godot --headless --script test_runner.gd` to run automated tests
- Create a test script that instantiates scenes and verifies behavior
- Check for parse errors: `godot --headless --check-only`

### Export for Web
```bash
# Install export templates
godot --headless --install-android-build-template  # only if needed
# Export to HTML5
godot --headless --export-release "HTML5" build/index.html
```

The exported HTML5 build can be served via `python3 -m http.server 8080` and played in browser.

## Evaluation Loop

After building each system:
1. Run `godot --headless --check-only` to verify no parse errors
2. Review the code: does the player controller feel right? Are the state machines clean?
3. Check scene tree structure: is it well organized?
4. Run any test scripts
5. If everything checks out: commit and push

## README.md Dashboard

Update after EVERY commit:
1. Current state — systems complete, what's playable
2. How to play — export instructions, controls
3. What's New — reverse-chronological
4. Known Issues
5. Next Up

## MANDATORY: Commit and Push After EVERY Change (NON-NEGOTIABLE)

**YOU MUST run `git add -A && git commit -m "description" && git push` after EVERY single change.** Commits are your heartbeat. No commits = no proof of life. This is the MOST IMPORTANT rule.

## Development Loop

LOOP FOREVER:

1. Build next highest-priority system
2. Verify with `godot --headless --check-only`
3. Commit and push
4. Update README.md
5. Repeat

**Priority order:**
1. project.godot + main scene structure
2. Player movement + animation states (MUST feel snappy)
3. Tilemap world generation
4. Basic combat (melee) with game feel (screen shake, hitstop, knockback)
5. 3 enemy types with AI
6. Inventory system
7. Survival mechanics
8. Crafting
9. Day/night cycle
10. Missions + story
11. UI polish
12. Audio
13. Save/load
14. HTML5 export + serve

**NEVER STOP.** If the game is "done," make it better. Add more enemy types, more items, better animations, tighter controls, more story. A game can always be more polished. The human is away.

**The bar**: Someone plays this and says "this feels like a real indie game, not a jam project." Tight controls, satisfying combat, interesting choices, and a story that makes them want to keep playing.
