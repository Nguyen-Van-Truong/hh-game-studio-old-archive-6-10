import Phaser from "phaser";
import { TestArena } from "../arenas/TestArena";
import { COLORS } from "../config";
import { Fighter } from "../entities/Fighter";
import { DEFAULT_MATCH, MATCH_REGISTRY_KEY, type MatchConfig } from "../match";
import {
  HOTSEAT_PLAYER_ONE_BINDINGS,
  HOTSEAT_PLAYER_TWO_BINDINGS,
  KeyboardController,
  SOLO_PLAYER_BINDINGS,
} from "../systems/InputController";

export class ArenaScene extends Phaser.Scene {
  private fighters: Fighter[] = [];

  constructor() {
    super("ArenaScene");
  }

  create(): void {
    const match = (this.registry.get(MATCH_REGISTRY_KEY) as MatchConfig | undefined) ?? DEFAULT_MATCH;
    const arena = new TestArena(this);
    const [spawnA, spawnB] = arena.spawnPoints();

    this.fighters = [];
    if (match.playerCount === 1) {
      const p1 = new KeyboardController(this, SOLO_PLAYER_BINDINGS);
      this.fighters.push(new Fighter(this, spawnA.x, spawnA.y, p1, COLORS.fighterIdle));
    } else {
      const p1 = new KeyboardController(this, HOTSEAT_PLAYER_ONE_BINDINGS);
      const p2 = new KeyboardController(this, HOTSEAT_PLAYER_TWO_BINDINGS);
      this.fighters.push(new Fighter(this, spawnA.x, spawnA.y, p1, COLORS.fighterIdle));
      this.fighters.push(new Fighter(this, spawnB.x, spawnB.y, p2, COLORS.fighterTwo));
    }

    const esc = this.input.keyboard?.addKey(Phaser.Input.Keyboard.KeyCodes.ESC);
    esc?.on("down", () => this.backToMenu());
  }

  update(time: number): void {
    for (const fighter of this.fighters) {
      fighter.update(time);
    }
  }

  private backToMenu(): void {
    this.scene.stop("HudScene");
    this.scene.start("MenuScene");
  }
}
