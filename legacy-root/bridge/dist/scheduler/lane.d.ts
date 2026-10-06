/** Single Godot mutation lane: one apply at a time. Staging workers never enter this. */
import type { LaneEvent } from "./types.js";
export declare function mutationLaneBusy(): boolean;
export declare function mutationLaneEvents(): LaneEvent[];
export declare function holdMutationLane(writerId: string): void;
export declare function releaseMutationLane(): void;
export declare function withMutationLane<T>(writerId: string, filePath: string, op: string, fn: () => T): T;
