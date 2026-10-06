import Phaser from "phaser";
import { GAME_WIDTH, GAME_HEIGHT, COLORS } from "../config";

interface Platform {
  x: number;
  y: number;
  width: number;
  height: number;
}

export class TestArena {
  readonly scene: Phaser.Scene;
  readonly platforms: Platform[];

  constructor(scene: Phaser.Scene) {
    this.scene = scene;

    const groundThickness = 48;
    this.platforms = [
      // Ground
      {
        x: GAME_WIDTH / 2,
        y: GAME_HEIGHT - groundThickness / 2,
        width: GAME_WIDTH,
        height: groundThickness,
      },
      // Left platform
      { x: 260, y: GAME_HEIGHT - 220, width: 240, height: 20 },
      // Right platform
      { x: GAME_WIDTH - 260, y: GAME_HEIGHT - 220, width: 240, height: 20 },
      // Center floating platform
      { x: GAME_WIDTH / 2, y: GAME_HEIGHT - 360, width: 280, height: 20 },
    ];

    for (const p of this.platforms) {
      scene.matter.add.rectangle(p.x, p.y, p.width, p.height, {
        isStatic: true,
        label: "terrain",
        friction: 0.8,
      });
      scene.add.rectangle(p.x, p.y, p.width, p.height, COLORS.terrain);
    }
  }

  spawnPoint(): { x: number; y: number } {
    return this.spawnPoints()[0];
  }

  spawnPoints(): [{ x: number; y: number }, { x: number; y: number }] {
    const y = GAME_HEIGHT - 500;
    return [
      { x: GAME_WIDTH / 2 - 120, y },
      { x: GAME_WIDTH / 2 + 120, y },
    ];
  }
}
