import { observable } from "mobx";
import { AppStore } from "./app_store";

export class ScanHookStore {
    constructor(readonly root: AppStore) {
        document.addEventListener("focus", () => {
            this.applyHookToFocused();
        }, true);
        document.addEventListener("blur", () => {
            this.applyHookToFocused();
        }, true);

        document.addEventListener("visibilitychange", () => {
            this.applyHookToFocused();
        });
    }

    @observable accessor autofill_enabled = true;

    get shouldApplyScanHook() {
        return this.root.paired_scanner_id && this.autofill_enabled && document.hasFocus() && document.activeElement instanceof HTMLInputElement;
    }

    handleHookedScan(payload: string) {
        if (this.shouldApplyScanHook) {
            const input = document.activeElement as HTMLInputElement;
            const start = input.selectionStart ?? 0;
            const end = input.selectionEnd ?? 0;
            const value = input.value;
            input.value = value.slice(0, start) + payload + value.slice(end);
            const cursorPos = start + payload.length;
            input.setSelectionRange(cursorPos, cursorPos);

            const event = new Event("input", { bubbles: true });
            input.dispatchEvent(event);
        }
    }

    private _hook_applied = false;
    protected applyHookToFocused() {
        const wanted = this.shouldApplyScanHook;
        if (wanted != this._hook_applied) {
            this._hook_applied = wanted;
            if (wanted) {
                this.root.uplink_channel.perform("take_scan_hook", { scanner_id: this.root.paired_scanner_id });
            } else {
                this.root.uplink_channel.perform("release_scan_hook");
            }
        }
    }
}
