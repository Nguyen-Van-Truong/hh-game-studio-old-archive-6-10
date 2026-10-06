export type GameMode = "versus" | "stage" | "survival";
export type PlayerCount = 1 | 2;

export interface MatchConfig {
  playerCount: PlayerCount;
  mode: GameMode;
}

export const DEFAULT_MATCH: MatchConfig = {
  playerCount: 1,
  mode: "versus",
};

export const MATCH_REGISTRY_KEY = "match";

export function modeLabel(mode: GameMode): string {
  switch (mode) {
    case "versus":
      return "VERSUS";
    case "stage":
      return "STAGE";
    case "survival":
      return "SURVIVAL";
  }
}

export function describeMatch(match: MatchConfig): string {
  const players = match.playerCount === 1 ? "1P" : "2P";
  return `${players}  ${modeLabel(match.mode)}`;
}
