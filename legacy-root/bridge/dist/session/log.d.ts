export interface SessionLog {
    info(message: string): void;
    error(message: string): void;
}
export declare function createSessionLog(secrets: () => readonly string[]): SessionLog;
