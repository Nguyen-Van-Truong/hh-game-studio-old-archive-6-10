# CLAUDE.md

Guidance for Claude Code working in this repo. Keep this file updated as architecture evolves.

## What this project is

`platform-fighter` is a browser-based 2D fighting game — a Superfighters / Superfighters Deluxe replica that expands on maps and weapons. Side-view arenas, physics-driven movement, guns + melee + grenades + environmental hazards, short matches with multiple fighters.

## Stack

- **Phaser 3** (game framework) — Scenes, GameObjects, input
- **Matter.js** — physics (accessed via `scene.matter` and `Phaser.Physics.Matter.Matter`). Ships inside Phaser; **do not** install `matter-js` separately.
- **TypeScript** (strict mode) — all gameplay code
- **Vite** — dev server and bundler

Local hotseat first. Online multiplayer is planned (likely Colyseus) but not yet in the codebase.

## Architecture conventions

### Scenes
- `BootScene` → `PreloadScene` → `MenuScene` → `ArenaScene` (+ `HudScene` overlay).
- Gameplay lives in `ArenaScene`. Menu picks 1P/2P and Versus/Stage/Survival (`src/match.ts`). ESC returns to menu.

### Entities (`src/entities/`)
Plain TS classes that **wrap** a Matter body and a visual. Not `Phaser.GameObjects.GameObject` subclasses — we want direct access to the Matter body and the ability to swap visuals. Each entity:
- Takes `scene` and spawn coords in its constructor
- Creates and owns its Matter body
- Creates and owns its visual(s)
- Exposes an `update(time)` method the scene calls

### Input — this is load-bearing
`Fighter` (and every future player-controllable entity) must **not** read from `scene.input.keyboard` directly. It reads from an `IntentFrame` produced by an `InputController`:

```ts
interface IntentFrame {
  moveX: -1 | 0 | 1;
  jumpPressed: boolean;
  punchPressed: boolean;
  // extend here as actions are added
}
```

Why it matters: adding a 2nd local player, gamepad, AI, or netplay = write a new controller. Fighter code is untouched. If you find yourself reaching for `scene.input` inside an entity, stop — add the action to `IntentFrame` instead.

Extend `IntentFrame` (not bypass it) when you add new actions.

### Config (`src/config.ts`)
Every tunable lives here — gravity, speeds, jump impulse, hitbox sizes, cooldowns, colors. **Do not** scatter magic numbers through entity code. If you find yourself writing `4.5` or `-10.5` inline, it belongs in `config.ts`.

### Placeholder visuals
Fighters and terrain are drawn with `Phaser.GameObjects.Rectangle` right now. When real art comes in, swap the rect for a `Sprite` inside the entity — everything else stays the same. No sprite assets exist yet; `PreloadScene.preload()` is currently empty.

### Physics labels
Matter bodies get string `label`s (`"fighter"`, `"terrain"`, later `"projectile"`, `"pickup"`, etc.). Use labels for collision routing rather than identity comparisons — it keeps things decoupled.

## Coding conventions

- Strict TS. Prefer `readonly` fields and `as const` literals where it communicates intent.
- Prefer explicit types on exported/public APIs; inference is fine internally.
- Default to no comments. Only comment *why* something non-obvious exists (e.g., the `inertia: Infinity` on fighter bodies — fighters stand upright).
- Keep entity `update()` methods small. Push non-trivial state machines into helper classes when they grow.

## Commands

```bash
npm install        # install deps
npm run dev        # dev server (hot reload)
npm run build      # tsc --noEmit && vite build  (this is what CI/verification uses)
npm run preview    # serve the production build
```

`npm run build` runs `tsc --noEmit` first — use it as the fast type-check in addition to a build.

## What's deliberately *not* here yet

Don't add these without discussing — they're queued in the roadmap and their designs may interact:

- AI bots (2nd local player is in)
- Distinct Stage / Survival rules (menu already selects the mode)
- Weapon system (deep design: pickups, ammo, aiming, projectiles)
- Damage & KO
- Data-driven maps
- Destructible terrain
- Online multiplayer
- Audio

When any of these land, update the Architecture section above so future sessions aren't surprised.
