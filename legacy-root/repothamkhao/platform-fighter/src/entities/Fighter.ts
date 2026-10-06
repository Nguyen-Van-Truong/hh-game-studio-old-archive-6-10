import Phaser from "phaser";
import { FIGHTER, PUNCH, COLORS } from "../config";
import type { InputController } from "../systems/InputController";

type MatterBody = MatterJS.BodyType;

export class Fighter {
  readonly scene: Phaser.Scene;
  readonly body: MatterBody;
  private readonly sprite: Phaser.GameObjects.Rectangle;
  private readonly punchDebug: Phaser.GameObjects.Rectangle;
  private readonly input: InputController;

  private facing: 1 | -1 = 1;
  private grounded = false;
  private lastGroundedAt = 0;
  private punchActiveUntil = 0;
  private punchReadyAt = 0;

  private readonly idleColor: number;

  constructor(
    scene: Phaser.Scene,
    x: number,
    y: number,
    input: InputController,
    idleColor: number = COLORS.fighterIdle,
  ) {
    this.scene = scene;
    this.input = input;
    this.idleColor = idleColor;

    this.body = scene.matter.add.rectangle(x, y, FIGHTER.width, FIGHTER.height, {
      friction: FIGHTER.friction,
      frictionAir: FIGHTER.airFriction,
      frictionStatic: 0.5,
      label: "fighter",
      chamfer: { radius: 4 },
    }) as MatterBody;
    // Fighters stand upright — infinite inertia prevents Matter from rotating them on collision.
    this.body.inertia = Infinity;
    this.body.inverseInertia = 0;

    this.sprite = scene.add.rectangle(x, y, FIGHTER.width, FIGHTER.height, idleColor);
    this.punchDebug = scene.add
      .rectangle(x, y, PUNCH.width, PUNCH.height, COLORS.punchHitbox, 0.7)
      .setVisible(false);
  }

  update(time: number): void {
    this.refreshGrounded(time);

    const intent = this.input.sample();

    if (intent.moveX !== 0) this.facing = intent.moveX;

    const vx = this.body.velocity.x;
    const targetVx = intent.moveX * FIGHTER.runSpeed;
    if (this.grounded) {
      this.scene.matter.body.setVelocity(this.body, {
        x: targetVx,
        y: this.body.velocity.y,
      });
    } else if (intent.moveX !== 0) {
      const blended = vx + (targetVx - vx) * FIGHTER.airControl * 0.15;
      this.scene.matter.body.setVelocity(this.body, {
        x: blended,
        y: this.body.velocity.y,
      });
    }

    // Coyote time — jump allowed briefly after leaving ground.
    const canJump = time - this.lastGroundedAt < FIGHTER.groundedGraceMs;
    if (intent.jumpPressed && canJump) {
      this.scene.matter.body.setVelocity(this.body, {
        x: this.body.velocity.x,
        y: FIGHTER.jumpImpulse,
      });
      this.grounded = false;
    }

    if (this.body.velocity.y > FIGHTER.maxFallSpeed) {
      this.scene.matter.body.setVelocity(this.body, {
        x: this.body.velocity.x,
        y: FIGHTER.maxFallSpeed,
      });
    }

    if (intent.punchPressed && time >= this.punchReadyAt) {
      this.punchActiveUntil = time + PUNCH.activeMs;
      this.punchReadyAt = time + PUNCH.cooldownMs;
    }
    const punching = time < this.punchActiveUntil;
    this.sprite.fillColor = punching ? COLORS.fighterPunching : this.idleColor;
    this.punchDebug.setVisible(punching);

    this.sprite.setPosition(this.body.position.x, this.body.position.y);
    this.punchDebug.setPosition(
      this.body.position.x + this.facing * (FIGHTER.width / 2 + PUNCH.reach / 2),
      this.body.position.y,
    );
  }

  private refreshGrounded(time: number): void {
    this.grounded = false;
    const pairs = this.scene.matter.world.engine.pairs.list;
    for (const pair of pairs) {
      if (!pair.isActive) continue;
      const { bodyA, bodyB, collision } = pair;
      const isA = bodyA === this.body;
      const isB = bodyB === this.body;
      if (!isA && !isB) continue;
      const other = isA ? bodyB : bodyA;
      if (other.label === "fighter") continue;
      // collision.normal points from A to B; flip if we're B.
      const ny = isA ? collision.normal.y : -collision.normal.y;
      if (ny < -0.5) {
        this.grounded = true;
        this.lastGroundedAt = time;
        return;
      }
    }
  }
}
