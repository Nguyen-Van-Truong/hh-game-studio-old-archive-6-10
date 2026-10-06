import Phaser from "phaser";
import { DEFAULT_MATCH, MATCH_REGISTRY_KEY, describeMatch, type MatchConfig } from "../match";

export class HudScene extends Phaser.Scene {
  constructor() {
    super({ key: "HudScene", active: false });
  }

  create(): void {
    const match = (this.registry.get(MATCH_REGISTRY_KEY) as MatchConfig | undefined) ?? DEFAULT_MATCH;
    const two = match.playerCount === 2;
    const controls = two
      ? "P1 A/D W jump J punch   P2 arrows L punch   Esc menu"
      : "A/D move  Space jump  J punch   Esc menu";

    this.add
      .text(12, 8, `${describeMatch(match)}   ·   ${controls}`, {
        fontFamily: "system-ui, sans-serif",
        fontSize: "14px",
        color: "#cfcfd6",
      })
      .setScrollFactor(0);
  }
}
