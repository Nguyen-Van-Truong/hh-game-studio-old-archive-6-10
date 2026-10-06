/** Single Godot mutation lane: one apply at a time. Staging workers never enter this. */
import { E, typedError } from "../registry/errors.js";
let busy = false;
const events = [];
export function mutationLaneBusy() {
    return busy;
}
export function mutationLaneEvents() {
    return [...events];
}
export function holdMutationLane(writerId) {
    if (busy) {
        throw typedError(E.E_BUSY, "godot mutation lane held by another writer", "lane");
    }
    busy = true;
    events.push({ at_ms: Date.now(), writer_id: writerId, path: "lane", op: "hold_lane" });
}
export function releaseMutationLane() {
    busy = false;
    events.push({ at_ms: Date.now(), writer_id: "", path: "lane", op: "release_lane" });
}
export function withMutationLane(writerId, filePath, op, fn) {
    if (busy) {
        throw typedError(E.E_BUSY, "godot mutation lane held by another writer", "lane");
    }
    busy = true;
    const started = Date.now();
    events.push({ at_ms: started, writer_id: writerId, path: filePath, op });
    try {
        return fn();
    }
    finally {
        busy = false;
    }
}
