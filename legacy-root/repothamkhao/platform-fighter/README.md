# platform-fighter

A browser-based 2D fighting game in the spirit of **Superfighters** / **Superfighters Deluxe**, aiming to expand on maps and weapons beyond the original. Inspired also by Smash and Brawlhalla.

**Stack:** Phaser 3 + TypeScript + Vite. Matter.js physics (shipped inside Phaser). Local hotseat first; online multiplayer planned later.

## Status

Y8-style menu: 1P/2P and Versus / Stage / Survival. One test arena. 2-player hotseat works. No weapons, health, bots, or distinct Stage/Survival rules yet.

## Getting started

Requires Node.js (tested on v25). No other global installs.

```bash
npm install
npm run dev        # dev server with hot reload, default http://localhost:5173
npm run build      # type-check + production build into dist/
npm run preview    # serve the production build
```

## Controls

| | P1 (solo also uses arrows) | P2 |
|---|---|---|
| Move | `A` / `D` | `←` / `→` |
| Jump | `W` / `Space` | `↑` |
| Punch | `J` | `L` |
| Menu | `Esc` | |

## Project layout

```
src/
  arenas/           # map / level definitions (TestArena for now)
  entities/         # in-world things — Fighter, later Weapon, Projectile, Pickup
  scenes/           # Phaser Scenes: Boot → Preload → Arena (+ Hud overlay)
  systems/          # cross-cutting systems — InputController (keyboard/net/AI → IntentFrame)
  config.ts         # gameplay constants (gravity, speeds, hitbox sizes, colors)
  main.ts           # Phaser.Game boot
```

Input is abstracted behind an `IntentFrame` so a fighter doesn't care whether it's driven by keyboard, gamepad, AI, or network — new input sources plug in without changing fighter code.

## Roadmap

See the initial plan in `C:\Users\klui\.claude\plans\happy-mapping-hopper.md` for the scaffold design. Next milestones (not yet implemented):

1. Local 2-player (second `KeyboardController` + mirrored keybinds)
2. Health, damage, KO, round reset
3. Weapon pickups (melee first, then firearms, then grenades)
4. Data-driven maps (JSON or Tiled) — unlocks the "expanded maps" goal
5. Destructible terrain
6. AI bots
7. Online multiplayer (likely Colyseus authoritative server)
