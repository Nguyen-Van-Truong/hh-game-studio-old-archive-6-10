/** In-memory ActionDef map. Dispatch is lookup only — no editor handlers. */
import { loadActionDefs } from "./actions.js";
import { requiredActionIds } from "./catalog.js";
const DEFS = loadActionDefs();
const BY_ID = new Map(DEFS.map((def) => [def.id, def]));
export function allActionDefs() {
    return DEFS;
}
export function getAction(id) {
    return BY_ID.get(id);
}
export function getRegistry() {
    return BY_ID;
}
export function actionCount() {
    return DEFS.length;
}
export function missingRequiredVerbs() {
    return requiredActionIds().filter((id) => !BY_ID.has(id));
}
export function actionIdFromMethod(method, action) {
    if (!method.startsWith("godot.")) {
        return null;
    }
    const group = method.slice("godot.".length);
    if (!group || group.includes(".")) {
        return null;
    }
    return `${group}.${action}`;
}
