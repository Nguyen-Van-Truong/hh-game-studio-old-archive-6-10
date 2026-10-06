export interface DiscoveredProject {
    root: string;
    projectId: string;
}
/** Walk up to project.godot; id is sha256(canonical root) truncated to 32 hex chars. */
export declare function discoverProject(inputPath: string): DiscoveredProject;
export declare function jailUnderProject(projectRoot: string, candidate: string): string;
