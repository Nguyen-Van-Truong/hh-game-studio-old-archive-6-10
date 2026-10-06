import { redactSecrets } from "./token.js";
export function createSessionLog(secrets) {
    const write = (line) => {
        process.stderr.write(`${redactSecrets(line, secrets())}\n`);
    };
    return {
        info: write,
        error: write,
    };
}
