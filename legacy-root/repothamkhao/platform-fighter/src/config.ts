export const GAME_WIDTH = 1280;
export const GAME_HEIGHT = 720;

export const PHYSICS = {
  gravityY: 1.2,
} as const;

export const FIGHTER = {
  width: 28,
  height: 56,
  runSpeed: 4.5,
  airControl: 0.6,
  jumpImpulse: -10.5,
  maxFallSpeed: 16,
  friction: 0.02,
  airFriction: 0.005,
  groundedGraceMs: 80,
} as const;

export const PUNCH = {
  reach: 32,
  width: 22,
  height: 30,
  activeMs: 120,
  cooldownMs: 260,
} as const;

export const COLORS = {
  background: 0x1a1a22,
  terrain: 0x3a3a48,
  fighterIdle: 0xe2c275,
  fighterTwo: 0x7eb8e8,
  fighterPunching: 0xf0a050,
  punchHitbox: 0xff4040,
  menuInk: 0xe8e4d4,
  menuMuted: 0x8a8678,
  menuButton: 0x2a2a34,
  menuButtonOn: 0xc4a24a,
} as const;
