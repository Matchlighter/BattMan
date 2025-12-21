import { generateToken } from "@/util";
import { action } from "mobx";

export class ClientCodesStore {
    private registered_handlers: Record<string, (scanner: any) => void> = {};

    @action handleCodeScanned(code: string, scanner: any) {
        const [token, ...restParts] = code.split(":");
        const rest = restParts.join(":");
        const handler = this.registered_handlers[token];
        if (handler) {
            handler(scanner);
        } else {
            console.warn(`No handler registered for client code token: ${token}`);
        }
    }

    registerClientCode(callback: (rest: string) => void)
    registerClientCode(code: string, callback: (rest: string) => void)
    registerClientCode(...args) {
        const callback = args.pop();
        const token = args[0] || generateToken();
        this.registered_handlers[token] = callback;
        return { token, unregister: () => {
            if (this.registered_handlers[token] == callback) {
                delete this.registered_handlers[token];
            }
        }}
    }
}
