/** Proven editor apply verbs. Scene, node, property, resource, signal, script, asset-ref. */
export declare const SCENE_LIFECYCLE_APPLY: readonly ["scene.create", "scene.open", "scene.save", "scene.save_as", "scene.reload", "scene.activate", "scene.close"];
export declare const NODE_CRUD_APPLY: readonly ["node.add", "node.remove", "node.rename", "node.reparent", "node.reorder", "node.duplicate", "node.group", "node.make_local", "node.undo", "node.redo", "scene.instantiate"];
export declare const PROPERTY_APPLY: readonly ["property.set", "property.batch", "property.reset"];
export declare const CANVAS_APPLY: readonly ["canvas.layout_batch"];
export declare const CAMERA_APPLY: readonly ["camera.make_current"];
export declare const TILEMAP_APPLY: readonly ["tilemap.tileset", "tilemap.source", "tilemap.terrain", "tilemap.layer", "tilemap.cell", "tilemap.fill", "tilemap.stamp"];
export declare const ANIMATION_APPLY: readonly ["animation.library", "animation.animation", "animation.track", "animation.key", "animation.sprite_frames", "animation.state_machine"];
export declare const UI_APPLY: readonly ["ui.control", "ui.theme", "ui.layout", "ui.anchor"];
export declare const PHYSICS_APPLY: readonly ["physics.body", "physics.shape", "physics.layers", "physics.nav_region", "physics.nav_agent"];
export declare const AUDIO_APPLY: readonly ["audio.player", "audio.bus"];
export declare const RENDER_APPLY: readonly ["render.shader", "render.particles", "render.quality"];
export declare const RESOURCE_APPLY: readonly ["resource.create", "resource.assign", "resource.duplicate", "resource.edit", "resource.save"];
export declare const SIGNAL_APPLY: readonly ["signal.connect", "signal.disconnect"];
export declare const ASSET_INGEST_APPLY: readonly ["asset.import", "asset.reimport"];
export declare const ASSET_REF_APPLY: readonly ["asset.move", "asset.rename", "asset.delete"];
export declare const SCRIPT_APPLY: readonly ["script.write", "script.patch", "script.attach", "script.detach", "script.rename"];
export declare const PROJECT_SETTINGS_APPLY: readonly ["project.settings", "project.input", "project.autoload", "project.plugin"];
export declare const SIDECAR_MUTATE_APPLY: readonly ["git.checkpoint", "git.revert_checkpoint", "job.schedule", "job.compact"];
/** EXTERNAL Play apply. Not UndoRedo / isProvenEditorApply. */
export declare const PLAY_APPLY: readonly ["play.start", "play.stop", "play.restart", "play.debug"];
/** EXTERNAL Play-process input. Not UndoRedo / isProvenEditorApply. */
export declare const INPUT_APPLY: readonly ["input.action", "input.key", "input.mouse", "input.touch", "input.sequence", "input.release_all"];
/** EXTERNAL Play-process freeze/step. Not UndoRedo / isProvenEditorApply. */
export declare const RUNTIME_APPLY: readonly ["runtime.freeze", "runtime.step", "runtime.screenshot", "runtime.perf"];
/** EXTERNAL/mutate test runner. Not UndoRedo / isProvenEditorApply. */
export declare const TEST_APPLY: readonly ["test.define", "test.run", "test.assert", "test.baseline", "test.repair"];
export declare const TRANSACTION_APPLY: readonly ["job.transaction"];
/** Orchestrator job.run / cancel / wait. Plugin when live; sidecar when plugin is down. */
export declare const ORCHESTRATOR_APPLY: readonly ["job.run", "job.cancel", "job.wait"];
/** Export job. Plugin accepts; sidecar/export_job.py supervises Godot CLI. */
export declare const EXPORT_APPLY: readonly ["export.preset", "export.build", "export.cancel"];
export declare const NODE_UID_AFTER: readonly ["node.add", "node.rename", "node.reparent", "node.reorder", "node.duplicate", "node.group", "scene.instantiate"];
export declare const SCENE_DURABLE_DISK: readonly ["scene.create", "scene.save", "scene.save_as"];
export declare function isSceneLifecycleApply(actionId: string): boolean;
export declare function isNodeCrudApply(actionId: string): boolean;
export declare function isPropertyApply(actionId: string): boolean;
export declare function isCanvasApply(actionId: string): boolean;
export declare function isCameraApply(actionId: string): boolean;
export declare function isTilemapApply(actionId: string): boolean;
export declare function isAnimationApply(actionId: string): boolean;
export declare function isUiApply(actionId: string): boolean;
export declare function isPhysicsApply(actionId: string): boolean;
export declare function isAudioApply(actionId: string): boolean;
export declare function isRenderApply(actionId: string): boolean;
export declare function isResourceApply(actionId: string): boolean;
export declare function isSignalApply(actionId: string): boolean;
export declare function isAssetIngestApply(actionId: string): boolean;
export declare function isAssetRefApply(actionId: string): boolean;
export declare function isScriptApply(actionId: string): boolean;
export declare function isProjectSettingsApply(actionId: string): boolean;
export declare function isSidecarMutateApply(actionId: string): boolean;
export declare function isPlayApply(actionId: string): boolean;
export declare function isInputApply(actionId: string): boolean;
export declare function isRuntimeApply(actionId: string): boolean;
export declare function isTestApply(actionId: string): boolean;
export declare function isTransactionApply(actionId: string): boolean;
export declare function isOrchestratorApply(actionId: string): boolean;
export declare function isExportApply(actionId: string): boolean;
export declare function isProvenEditorApply(actionId: string): boolean;
export declare function sceneNeedsDiskHash(actionId: string): boolean;
export declare function mutationNeedsDiskHash(actionId: string, params: Record<string, unknown>): boolean;
export declare function durableResPath(actionId: string, params: Record<string, unknown>, after?: Record<string, unknown>): string;
export declare function nodeNeedsUidAfter(actionId: string): boolean;
