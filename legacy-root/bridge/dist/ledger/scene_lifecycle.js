/** Proven editor apply verbs. Scene, node, property, resource, signal, script, asset-ref. */
export const SCENE_LIFECYCLE_APPLY = [
    "scene.create",
    "scene.open",
    "scene.save",
    "scene.save_as",
    "scene.reload",
    "scene.activate",
    "scene.close",
];
export const NODE_CRUD_APPLY = [
    "node.add",
    "node.remove",
    "node.rename",
    "node.reparent",
    "node.reorder",
    "node.duplicate",
    "node.group",
    "node.make_local",
    "node.undo",
    "node.redo",
    "scene.instantiate",
];
export const PROPERTY_APPLY = ["property.set", "property.batch", "property.reset"];
export const CANVAS_APPLY = ["canvas.layout_batch"];
export const CAMERA_APPLY = ["camera.make_current"];
export const TILEMAP_APPLY = [
    "tilemap.tileset",
    "tilemap.source",
    "tilemap.terrain",
    "tilemap.layer",
    "tilemap.cell",
    "tilemap.fill",
    "tilemap.stamp",
];
export const ANIMATION_APPLY = [
    "animation.library",
    "animation.animation",
    "animation.track",
    "animation.key",
    "animation.sprite_frames",
    "animation.state_machine",
];
export const UI_APPLY = ["ui.control", "ui.theme", "ui.layout", "ui.anchor"];
export const PHYSICS_APPLY = [
    "physics.body",
    "physics.shape",
    "physics.layers",
    "physics.nav_region",
    "physics.nav_agent",
];
export const AUDIO_APPLY = ["audio.player", "audio.bus"];
export const RENDER_APPLY = ["render.shader", "render.particles", "render.quality"];
export const RESOURCE_APPLY = [
    "resource.create",
    "resource.assign",
    "resource.duplicate",
    "resource.edit",
    "resource.save",
];
export const SIGNAL_APPLY = ["signal.connect", "signal.disconnect"];
export const ASSET_INGEST_APPLY = ["asset.import", "asset.reimport"];
export const ASSET_REF_APPLY = ["asset.move", "asset.rename", "asset.delete"];
export const SCRIPT_APPLY = [
    "script.write",
    "script.patch",
    "script.attach",
    "script.detach",
    "script.rename",
];
export const PROJECT_SETTINGS_APPLY = [
    "project.settings",
    "project.input",
    "project.autoload",
    "project.plugin",
];
export const SIDECAR_MUTATE_APPLY = ["git.checkpoint", "git.revert_checkpoint", "job.schedule", "job.compact"];
/** EXTERNAL Play apply. Not UndoRedo / isProvenEditorApply. */
export const PLAY_APPLY = ["play.start", "play.stop", "play.restart", "play.debug"];
/** EXTERNAL Play-process input. Not UndoRedo / isProvenEditorApply. */
export const INPUT_APPLY = [
    "input.action",
    "input.key",
    "input.mouse",
    "input.touch",
    "input.sequence",
    "input.release_all",
];
/** EXTERNAL Play-process freeze/step. Not UndoRedo / isProvenEditorApply. */
export const RUNTIME_APPLY = [
    "runtime.freeze",
    "runtime.step",
    "runtime.screenshot",
    "runtime.perf",
];
/** EXTERNAL/mutate test runner. Not UndoRedo / isProvenEditorApply. */
export const TEST_APPLY = [
    "test.define",
    "test.run",
    "test.assert",
    "test.baseline",
    "test.repair",
];
export const TRANSACTION_APPLY = ["job.transaction"];
/** Orchestrator job.run / cancel / wait. Plugin when live; sidecar when plugin is down. */
export const ORCHESTRATOR_APPLY = ["job.run", "job.cancel", "job.wait"];
/** Export job. Plugin accepts; sidecar/export_job.py supervises Godot CLI. */
export const EXPORT_APPLY = ["export.preset", "export.build", "export.cancel"];
export const NODE_UID_AFTER = [
    "node.add",
    "node.rename",
    "node.reparent",
    "node.reorder",
    "node.duplicate",
    "node.group",
    "scene.instantiate",
];
export const SCENE_DURABLE_DISK = ["scene.create", "scene.save", "scene.save_as"];
export function isSceneLifecycleApply(actionId) {
    return SCENE_LIFECYCLE_APPLY.includes(actionId);
}
export function isNodeCrudApply(actionId) {
    return NODE_CRUD_APPLY.includes(actionId);
}
export function isPropertyApply(actionId) {
    return PROPERTY_APPLY.includes(actionId);
}
export function isCanvasApply(actionId) {
    return CANVAS_APPLY.includes(actionId);
}
export function isCameraApply(actionId) {
    return CAMERA_APPLY.includes(actionId);
}
export function isTilemapApply(actionId) {
    return TILEMAP_APPLY.includes(actionId);
}
export function isAnimationApply(actionId) {
    return ANIMATION_APPLY.includes(actionId);
}
export function isUiApply(actionId) {
    return UI_APPLY.includes(actionId);
}
export function isPhysicsApply(actionId) {
    return PHYSICS_APPLY.includes(actionId);
}
export function isAudioApply(actionId) {
    return AUDIO_APPLY.includes(actionId);
}
export function isRenderApply(actionId) {
    return RENDER_APPLY.includes(actionId);
}
export function isResourceApply(actionId) {
    return RESOURCE_APPLY.includes(actionId);
}
export function isSignalApply(actionId) {
    return SIGNAL_APPLY.includes(actionId);
}
export function isAssetIngestApply(actionId) {
    return ASSET_INGEST_APPLY.includes(actionId);
}
export function isAssetRefApply(actionId) {
    return ASSET_REF_APPLY.includes(actionId);
}
export function isScriptApply(actionId) {
    return SCRIPT_APPLY.includes(actionId);
}
export function isProjectSettingsApply(actionId) {
    return PROJECT_SETTINGS_APPLY.includes(actionId);
}
export function isSidecarMutateApply(actionId) {
    return SIDECAR_MUTATE_APPLY.includes(actionId);
}
export function isPlayApply(actionId) {
    return PLAY_APPLY.includes(actionId);
}
export function isInputApply(actionId) {
    return INPUT_APPLY.includes(actionId);
}
export function isRuntimeApply(actionId) {
    return RUNTIME_APPLY.includes(actionId);
}
export function isTestApply(actionId) {
    return TEST_APPLY.includes(actionId);
}
export function isTransactionApply(actionId) {
    return TRANSACTION_APPLY.includes(actionId);
}
export function isOrchestratorApply(actionId) {
    return ORCHESTRATOR_APPLY.includes(actionId);
}
export function isExportApply(actionId) {
    return EXPORT_APPLY.includes(actionId);
}
export function isProvenEditorApply(actionId) {
    return (isSceneLifecycleApply(actionId) ||
        isNodeCrudApply(actionId) ||
        isPropertyApply(actionId) ||
        isCanvasApply(actionId) ||
        isCameraApply(actionId) ||
        isTilemapApply(actionId) ||
        isAnimationApply(actionId) ||
        isUiApply(actionId) ||
        isPhysicsApply(actionId) ||
        isAudioApply(actionId) ||
        isRenderApply(actionId) ||
        isResourceApply(actionId) ||
        isSignalApply(actionId) ||
        isAssetRefApply(actionId) ||
        isAssetIngestApply(actionId) ||
        isScriptApply(actionId) ||
        isProjectSettingsApply(actionId) ||
        isTransactionApply(actionId));
}
export function sceneNeedsDiskHash(actionId) {
    return SCENE_DURABLE_DISK.includes(actionId);
}
function isExternalResPath(path) {
    return (path.endsWith(".tres") || path.endsWith(".res")) && !path.includes("::");
}
function isGdPath(path) {
    return path.endsWith(".gd") && path.startsWith("res://") && !path.includes("::");
}
function isGdshaderPath(path) {
    return path.endsWith(".gdshader") && path.startsWith("res://") && !path.includes("::");
}
export function mutationNeedsDiskHash(actionId, params) {
    if (sceneNeedsDiskHash(actionId)) {
        return true;
    }
    if (actionId === "resource.create" || actionId === "resource.save") {
        return typeof params.path === "string" && isExternalResPath(params.path);
    }
    // unique=true is dest file-copy + RAM edit; the field is durable only after resource.save.
    if (actionId === "resource.duplicate") {
        return typeof params.dest === "string" && isExternalResPath(params.dest);
    }
    if (actionId === "script.write") {
        return typeof params.path === "string" && isGdPath(params.path);
    }
    if (actionId === "script.patch") {
        return params.buffer_only !== true && typeof params.path === "string" && isGdPath(params.path);
    }
    if (actionId === "script.rename") {
        return true;
    }
    if (actionId === "asset.import" || actionId === "asset.reimport") {
        return typeof params.path === "string" && params.path.startsWith("res://");
    }
    if (actionId === "tilemap.source" ||
        actionId === "tilemap.terrain" ||
        actionId === "tilemap.tileset") {
        return typeof params.tileset === "string" && isExternalResPath(params.tileset);
    }
    if (actionId === "animation.sprite_frames") {
        return typeof params.path === "string" && isExternalResPath(params.path);
    }
    if (actionId === "animation.library") {
        return typeof params.library_path === "string" && isExternalResPath(params.library_path);
    }
    if (actionId === "ui.theme") {
        return typeof params.theme === "string" && isExternalResPath(params.theme);
    }
    if (actionId === "physics.shape") {
        return typeof params.shape_path === "string" && isExternalResPath(params.shape_path);
    }
    if (actionId === "physics.body") {
        return typeof params.material === "string" && isExternalResPath(params.material);
    }
    if (actionId === "physics.nav_region") {
        return typeof params.navpoly_path === "string" && isExternalResPath(params.navpoly_path);
    }
    if (actionId === "audio.player") {
        return typeof params.stream === "string" && isExternalResPath(params.stream);
    }
    if (actionId === "audio.bus") {
        return typeof params.layout === "string" && isExternalResPath(params.layout);
    }
    if (actionId === "render.shader") {
        const shader = typeof params.shader === "string" ? params.shader : "";
        const material = typeof params.material === "string" ? params.material : "";
        return isGdshaderPath(shader) || isExternalResPath(shader) || isExternalResPath(material);
    }
    if (actionId === "render.particles") {
        return typeof params.process_material === "string" && isExternalResPath(params.process_material);
    }
    if (actionId === "render.quality") {
        return typeof params.environment === "string" && isExternalResPath(params.environment);
    }
    if (actionId === "job.transaction") {
        if (params.save === true) {
            return true;
        }
        const steps = Array.isArray(params.steps) ? params.steps : [];
        return steps.some((step) => {
            if (!step || typeof step !== "object" || Array.isArray(step)) {
                return false;
            }
            const action = step.action;
            return action === "scene.save" || action === "scene.create" || action === "script.write";
        });
    }
    return actionId === "asset.move" || actionId === "asset.rename";
}
export function durableResPath(actionId, params, after) {
    const source = typeof params.path === "string" ? params.path : "";
    if (after &&
        typeof after.path === "string" &&
        after.path.startsWith("res://") &&
        (isExternalResPath(after.path) || isGdPath(after.path) || isGdshaderPath(after.path))) {
        if (actionId === "asset.move" ||
            actionId === "asset.rename" ||
            actionId === "resource.duplicate" ||
            actionId === "script.rename") {
            return after.path;
        }
        if (actionId === "resource.edit" && after.path !== source) {
            return after.path;
        }
    }
    if ((actionId === "tilemap.source" ||
        actionId === "tilemap.terrain" ||
        actionId === "tilemap.tileset") &&
        typeof params.tileset === "string" &&
        isExternalResPath(params.tileset)) {
        return params.tileset;
    }
    if (actionId === "animation.sprite_frames" &&
        typeof params.path === "string" &&
        isExternalResPath(params.path)) {
        return params.path;
    }
    if (actionId === "animation.library" &&
        typeof params.library_path === "string" &&
        isExternalResPath(params.library_path)) {
        return params.library_path;
    }
    if (actionId === "ui.theme" && typeof params.theme === "string" && isExternalResPath(params.theme)) {
        return params.theme;
    }
    if (actionId === "physics.shape" &&
        typeof params.shape_path === "string" &&
        isExternalResPath(params.shape_path)) {
        return params.shape_path;
    }
    if (actionId === "physics.body" && typeof params.material === "string" && isExternalResPath(params.material)) {
        return params.material;
    }
    if (actionId === "physics.nav_region" &&
        typeof params.navpoly_path === "string" &&
        isExternalResPath(params.navpoly_path)) {
        return params.navpoly_path;
    }
    if (actionId === "audio.player" && typeof params.stream === "string" && isExternalResPath(params.stream)) {
        return params.stream;
    }
    if (actionId === "audio.bus" && typeof params.layout === "string" && isExternalResPath(params.layout)) {
        return params.layout;
    }
    if (actionId === "render.shader") {
        if (typeof params.shader === "string" && (isGdshaderPath(params.shader) || isExternalResPath(params.shader))) {
            return params.shader;
        }
        if (typeof params.material === "string" && isExternalResPath(params.material)) {
            return params.material;
        }
    }
    if (actionId === "render.particles" &&
        typeof params.process_material === "string" &&
        isExternalResPath(params.process_material)) {
        return params.process_material;
    }
    if (actionId === "render.quality" &&
        typeof params.environment === "string" &&
        isExternalResPath(params.environment)) {
        return params.environment;
    }
    if (actionId === "resource.duplicate" && typeof params.dest === "string") {
        return params.dest;
    }
    if (actionId === "resource.edit" && params.unique === true && typeof params.dest === "string") {
        return params.dest;
    }
    if (actionId === "asset.move" && typeof params.to === "string") {
        return params.to;
    }
    if (actionId === "job.transaction") {
        if (after && typeof after.path === "string" && after.path.startsWith("res://")) {
            return after.path;
        }
        if (after && typeof after.scene === "string" && after.scene.startsWith("res://")) {
            return after.scene;
        }
        const steps = Array.isArray(params.steps) ? params.steps : [];
        for (let i = steps.length - 1; i >= 0; i -= 1) {
            const step = steps[i];
            if (!step || typeof step !== "object" || Array.isArray(step)) {
                continue;
            }
            const rec = step;
            const child = rec.params && typeof rec.params === "object" && !Array.isArray(rec.params)
                ? rec.params
                : {};
            if ((rec.action === "scene.save" || rec.action === "scene.create") && typeof child.path === "string") {
                return child.path;
            }
            if (rec.action === "script.write" && typeof child.path === "string") {
                return child.path;
            }
        }
    }
    return source;
}
export function nodeNeedsUidAfter(actionId) {
    return NODE_UID_AFTER.includes(actionId);
}
