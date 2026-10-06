/** In-memory ActionDef map. Dispatch is lookup only — no editor handlers. */
import type { ActionDef } from "./types.js";
export declare function allActionDefs(): readonly ActionDef[];
export declare function getAction(id: string): ActionDef | undefined;
export declare function getRegistry(): ReadonlyMap<string, ActionDef>;
export declare function actionCount(): number;
export declare function missingRequiredVerbs(): string[];
export declare function actionIdFromMethod(method: string, action: string): string | null;
