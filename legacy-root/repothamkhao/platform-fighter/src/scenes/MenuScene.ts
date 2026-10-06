import Phaser from "phaser";
import { COLORS, GAME_HEIGHT, GAME_WIDTH } from "../config";
import {
  DEFAULT_MATCH,
  MATCH_REGISTRY_KEY,
  type GameMode,
  type MatchConfig,
  type PlayerCount,
} from "../match";

interface ChoiceButton {
  readonly key: string;
  readonly hit: Phaser.GameObjects.Rectangle;
  readonly label: Phaser.GameObjects.Text;
  setOn(on: boolean): void;
}

export class MenuScene extends Phaser.Scene {
  private match: MatchConfig = { ...DEFAULT_MATCH };

  constructor() {
    super("MenuScene");
  }

  create(): void {
    const saved = this.registry.get(MATCH_REGISTRY_KEY) as MatchConfig | undefined;
    this.match = saved ? { ...saved } : { ...DEFAULT_MATCH };

    this.add.rectangle(GAME_WIDTH / 2, GAME_HEIGHT / 2, GAME_WIDTH, GAME_HEIGHT, COLORS.background);

    this.add
      .text(GAME_WIDTH / 2, 118, "FIGHTERS", {
        fontFamily: "Impact, Haettenschweiler, Arial Black, sans-serif",
        fontSize: "84px",
        color: "#e8e4d4",
      })
      .setOrigin(0.5);

    this.add
      .text(GAME_WIDTH / 2, 186, "1 or 2 players  ·  punch, then pick up guns later", {
        fontFamily: "system-ui, sans-serif",
        fontSize: "16px",
        color: "#8a8678",
      })
      .setOrigin(0.5);

    this.add
      .text(GAME_WIDTH / 2, 248, "PLAYERS", {
        fontFamily: "system-ui, sans-serif",
        fontSize: "13px",
        color: "#8a8678",
      })
      .setOrigin(0.5);

    const playerButtons = [
      this.makeButton(GAME_WIDTH / 2 - 130, 300, 220, 56, "1 PLAYER", "p1"),
      this.makeButton(GAME_WIDTH / 2 + 130, 300, 220, 56, "2 PLAYERS", "p2"),
    ];
    playerButtons[0].hit.on("pointerdown", () => this.setPlayers(1, playerButtons));
    playerButtons[1].hit.on("pointerdown", () => this.setPlayers(2, playerButtons));

    this.add
      .text(GAME_WIDTH / 2, 372, "MODE", {
        fontFamily: "system-ui, sans-serif",
        fontSize: "13px",
        color: "#8a8678",
      })
      .setOrigin(0.5);

    const modeButtons = [
      this.makeButton(GAME_WIDTH / 2 - 230, 424, 200, 56, "VERSUS", "versus"),
      this.makeButton(GAME_WIDTH / 2, 424, 200, 56, "STAGE", "stage"),
      this.makeButton(GAME_WIDTH / 2 + 230, 424, 200, 56, "SURVIVAL", "survival"),
    ];
    modeButtons[0].hit.on("pointerdown", () => this.setMode("versus", modeButtons));
    modeButtons[1].hit.on("pointerdown", () => this.setMode("stage", modeButtons));
    modeButtons[2].hit.on("pointerdown", () => this.setMode("survival", modeButtons));

    const start = this.makeButton(GAME_WIDTH / 2, 540, 280, 64, "START  ·  SPACE", "start");
    start.setOn(true);
    start.hit.on("pointerdown", () => this.startMatch());

    this.add
      .text(GAME_WIDTH / 2, 640, "P1  A/D  W/Space jump  J punch     P2  arrows  L punch     Esc menu", {
        fontFamily: "system-ui, sans-serif",
        fontSize: "14px",
        color: "#8a8678",
      })
      .setOrigin(0.5);

    this.refreshPlayers(playerButtons);
    this.refreshModes(modeButtons);

    const space = this.input.keyboard?.addKey(Phaser.Input.Keyboard.KeyCodes.SPACE);
    space?.on("down", () => this.startMatch());
  }

  private setPlayers(count: PlayerCount, buttons: ChoiceButton[]): void {
    this.match.playerCount = count;
    this.refreshPlayers(buttons);
  }

  private setMode(mode: GameMode, buttons: ChoiceButton[]): void {
    this.match.mode = mode;
    this.refreshModes(buttons);
  }

  private refreshPlayers(buttons: ChoiceButton[]): void {
    buttons[0].setOn(this.match.playerCount === 1);
    buttons[1].setOn(this.match.playerCount === 2);
  }

  private refreshModes(buttons: ChoiceButton[]): void {
    buttons[0].setOn(this.match.mode === "versus");
    buttons[1].setOn(this.match.mode === "stage");
    buttons[2].setOn(this.match.mode === "survival");
  }

  private startMatch(): void {
    this.registry.set(MATCH_REGISTRY_KEY, { ...this.match });
    this.scene.start("ArenaScene");
    this.scene.launch("HudScene");
  }

  private makeButton(
    x: number,
    y: number,
    width: number,
    height: number,
    text: string,
    key: string,
  ): ChoiceButton {
    const hit = this.add
      .rectangle(x, y, width, height, COLORS.menuButton)
      .setInteractive({ useHandCursor: true })
      .setStrokeStyle(2, 0x4a4a58);

    const label = this.add
      .text(x, y, text, {
        fontFamily: "system-ui, sans-serif",
        fontSize: "20px",
        color: "#e8e4d4",
      })
      .setOrigin(0.5);

    const setOn = (on: boolean): void => {
      hit.setFillStyle(on ? COLORS.menuButtonOn : COLORS.menuButton);
      label.setColor(on ? "#1a1a22" : "#e8e4d4");
    };

    return { key, hit, label, setOn };
  }
}
