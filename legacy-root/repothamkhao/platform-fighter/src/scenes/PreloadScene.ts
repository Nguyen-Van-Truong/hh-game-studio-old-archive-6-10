import Phaser from "phaser";

export class PreloadScene extends Phaser.Scene {
  constructor() {
    super("PreloadScene");
  }

  preload(): void {
    // No assets yet — placeholder rectangles are drawn with Graphics.
  }

  create(): void {
    this.scene.start("MenuScene");
  }
}
