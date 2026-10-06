import Phaser from "phaser";
import { GAME_WIDTH, GAME_HEIGHT, COLORS, PHYSICS } from "./config";
import { BootScene } from "./scenes/BootScene";
import { PreloadScene } from "./scenes/PreloadScene";
import { MenuScene } from "./scenes/MenuScene";
import { ArenaScene } from "./scenes/ArenaScene";
import { HudScene } from "./scenes/HudScene";

new Phaser.Game({
  type: Phaser.AUTO,
  parent: "game",
  width: GAME_WIDTH,
  height: GAME_HEIGHT,
  backgroundColor: COLORS.background,
  pixelArt: false,
  scale: {
    mode: Phaser.Scale.FIT,
    autoCenter: Phaser.Scale.CENTER_BOTH,
  },
  physics: {
    default: "matter",
    matter: {
      gravity: { x: 0, y: PHYSICS.gravityY },
      debug: {
        showBody: true,
        showStaticBody: true,
      },
    },
  },
  scene: [BootScene, PreloadScene, MenuScene, ArenaScene, HudScene],
});
