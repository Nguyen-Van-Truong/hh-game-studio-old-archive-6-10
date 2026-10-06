/** A8 path jail: canonicalize under project root; reject escape, device, reserved, overlong. */
export declare const DEFAULT_MAX_PATH_CHARS = 240;
export interface JailOk {
    ok: true;
    abs: string;
    rel: string;
}
export interface JailErr {
    ok: false;
    error: {
        code: string;
        message: string;
        path: string;
    };
}
export type JailResult = JailOk | JailErr;
export declare function stripResScheme(raw: string): string;
export declare function collapsePosix(s: string): string;
export declare function isLockedProjectRel(rel: string): boolean;
export declare function jailExportOutDir(candidate: string, repoRoot?: string, opts?: {
    maxPathChars?: number;
}): JailResult;
export declare function jailProjectPath(projectRoot: string, candidate: string, opts?: {
    maxPathChars?: number;
    forWrite?: boolean;
    allowProjectGodot?: boolean;
    allowExportPresets?: boolean;
}): JailResult;
export declare function extractTargetPaths(params: Record<string, unknown>, actionId?: string): string[];
