import Phaser from "phaser";

export interface IntentFrame {
  moveX: -1 | 0 | 1;
  jumpPressed: boolean;
  punchPressed: boolean;
}

export interface InputController {
  sample(): IntentFrame;
  destroy(): void;
}

export interface KeyboardBindings {
  left: number;
  right: number;
  jump: number;
  punch: number;
  altLeft?: number;
  altRight?: number;
  altJump?: number;
}

export class KeyboardController implements InputController {
  private readonly keys: {
    left: Phaser.Input.Keyboard.Key;
    right: Phaser.Input.Keyboard.Key;
    jump: Phaser.Input.Keyboard.Key;
    punch: Phaser.Input.Keyboard.Key;
    altLeft?: Phaser.Input.Keyboard.Key;
    altRight?: Phaser.Input.Keyboard.Key;
    altJump?: Phaser.Input.Keyboard.Key;
  };

  constructor(scene: Phaser.Scene, bindings: KeyboardBindings) {
    const kb = scene.input.keyboard;
    if (!kb) {
      throw new Error("KeyboardController: keyboard plugin unavailable");
    }
    this.keys = {
      left: kb.addKey(bindings.left),
      right: kb.addKey(bindings.right),
      jump: kb.addKey(bindings.jump),
      punch: kb.addKey(bindings.punch),
      altLeft: bindings.altLeft != null ? kb.addKey(bindings.altLeft) : undefined,
      altRight: bindings.altRight != null ? kb.addKey(bindings.altRight) : undefined,
      altJump: bindings.altJump != null ? kb.addKey(bindings.altJump) : undefined,
    };
  }

  sample(): IntentFrame {
    const leftDown = this.keys.left.isDown || this.keys.altLeft?.isDown === true;
    const rightDown = this.keys.right.isDown || this.keys.altRight?.isDown === true;
    const moveX: -1 | 0 | 1 = leftDown === rightDown ? 0 : leftDown ? -1 : 1;

    const jumpPressed =
      Phaser.Input.Keyboard.JustDown(this.keys.jump) ||
      (this.keys.altJump ? Phaser.Input.Keyboard.JustDown(this.keys.altJump) : false);

    const punchPressed = Phaser.Input.Keyboard.JustDown(this.keys.punch);

    return { moveX, jumpPressed, punchPressed };
  }

  destroy(): void {
    // Phaser keys are cleaned up with the scene; nothing extra needed.
  }
}

export const DEFAULT_PLAYER_ONE_BINDINGS: KeyboardBindings = {
  left: Phaser.Input.Keyboard.KeyCodes.A,
  right: Phaser.Input.Keyboard.KeyCodes.D,
  jump: Phaser.Input.Keyboard.KeyCodes.SPACE,
  punch: Phaser.Input.Keyboard.KeyCodes.J,
  altLeft: Phaser.Input.Keyboard.KeyCodes.LEFT,
  altRight: Phaser.Input.Keyboard.KeyCodes.RIGHT,
  altJump: Phaser.Input.Keyboard.KeyCodes.W,
};

export const SOLO_PLAYER_BINDINGS: KeyboardBindings = DEFAULT_PLAYER_ONE_BINDINGS;

export const HOTSEAT_PLAYER_ONE_BINDINGS: KeyboardBindings = {
  left: Phaser.Input.Keyboard.KeyCodes.A,
  right: Phaser.Input.Keyboard.KeyCodes.D,
  jump: Phaser.Input.Keyboard.KeyCodes.W,
  punch: Phaser.Input.Keyboard.KeyCodes.J,
  altJump: Phaser.Input.Keyboard.KeyCodes.SPACE,
};

export const HOTSEAT_PLAYER_TWO_BINDINGS: KeyboardBindings = {
  left: Phaser.Input.Keyboard.KeyCodes.LEFT,
  right: Phaser.Input.Keyboard.KeyCodes.RIGHT,
  jump: Phaser.Input.Keyboard.KeyCodes.UP,
  punch: Phaser.Input.Keyboard.KeyCodes.L,
};
