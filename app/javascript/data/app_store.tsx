import { Subscription } from "@rails/actioncable";
import type { useAppProps } from "antd/es/app/context";
import { action, computed, observable, reaction, runInAction } from "mobx";
import React from "react";

import { CABLE, Message } from "@/cable";
import { ScanHookStore } from "./scan_hooking";
import { ClientCodesStore } from "./client_codes";

const HID_CONFIG = {
    min_length: 4,
    minimum_rate_limit_ms: 30,
    prefix: "", // e.g., "\u001D" for some scanners
    suffix: "\n", // e.g., "\n" or a special character
}

export class AppStore {
    static instance = new AppStore();
    static Context = React.createContext(AppStore.instance);

    readonly uplink_channel: Subscription;
    readonly scan_hook_store = new ScanHookStore(this);
    readonly client_codes_store = new ClientCodesStore();

    constructor() {
        window["APPSTORE"] = this;

        window.addEventListener("resize", action(() => {
            this.refreshWindowHeight();
        }));
        this.refreshWindowHeight();

        this.listenForHIDScans();

        reaction(() => this.isSmallDevice, (isSmallDevice) => {
            this.sidebarCollapsed = isSmallDevice;
        }, { fireImmediately: true });

        this.client_codes_store.registerClientCode("LINK", (rest: string) => {
            this.linkScanner(rest);
        });

        this.uplink_channel = CABLE.subscriptions.create({ channel: "ClientChannel" }, {
            assign_uid: (data: Message<{ uid: string }>) => {
                this.client_uid = data.uid;
            },
            client_scanned: (data: Message<{ scanner_id: string; payload: string }>) => {
                console.log(`Scanned from scanner ${data.scanner_id}: ${data.payload}`);
                this.client_codes_store.handleCodeScanned(data.payload, data.scanner_id);
            },
            scan: (data: Message<{ payload: string, hooked: boolean }>) => {
                if (data.hooked) {
                    this.scan_hook_store.handleHookedScan(data.payload);
                }
            },
            received(data) {
                runInAction(() => {
                    if (this[data.type]) {
                        this[data.type](data);
                    } else {
                        console.error(`Unknown message type: ${data.type}`);
                    }
                })
            }
        });
    }

    client_uid: string;

    @observable accessor paired_scanner_id: string;
    @observable accessor follow_scans = false;

    ant: useAppProps;

    @observable accessor sidebarCollapsed = false;
    @observable accessor isSmallDevice = false;

    @action refreshWindowHeight() {
        this.isSmallDevice = window.innerWidth < 550;
    }

    @computed get isCompactNavBar() {
        return !this.isSmallDevice && this.sidebarCollapsed;
    }

    private _scanner_channel: Subscription;

    @action linkScanner(scanner_id: string) {
        this.unlinkScanner();

        this.paired_scanner_id = scanner_id;
        this._scanner_channel = CABLE.subscriptions.create({ channel: "ScannerChannel", scanner_id }, {
            scan: (data: Message<{ status: string, message: string, payload: string }>) => {
                if (data.status == "error") {
                    if (data.message == "URL Scanned") {
                        this.ant.modal.confirm({
                            title: "Scanned URL",
                            content: <>
                                <p>A URL was scanned - open it?</p>
                                <p>{data.payload}</p>
                            </>,
                            onOk() {
                                window.open(data.payload, "_blank");
                            },
                        });
                        return;
                    }
                } else {
                    if (this.follow_scans) {
                        // TODO Navigate to relevant thing page
                    }
                }
            },
            received(data) {
                runInAction(() => {
                    if (this[data.type]) {
                        this[data.type](data);
                    } else {
                        console.error(`Unknown message type: ${data.type}`);
                    }
                })
            },
            disconnected: action(() => {
                this.unlinkScanner();
            }),
        });
    }

    @action.bound unlinkScanner() {
        this.paired_scanner_id = null;
        this._scanner_channel?.unsubscribe();
        this._scanner_channel = null;
    }

    private listenForHIDScans() {
        let fast_keys = [];
        let last_key_time_ms = 0;
        let scan_commit_timer;
        const commit_hid_code = () => {
            const raw_code = fast_keys.join('');

            // Check if code matches expected prefix/suffix pattern
            const hasPrefix = !HID_CONFIG.prefix || raw_code.startsWith(HID_CONFIG.prefix);
            const hasSuffix = !HID_CONFIG.suffix || raw_code.endsWith(HID_CONFIG.suffix);

            if (hasPrefix && hasSuffix) {
                let scanned_code = raw_code;

                // Strip prefix and suffix if configured
                if (HID_CONFIG.prefix) {
                    scanned_code = scanned_code.slice(HID_CONFIG.prefix.length);
                }
                if (HID_CONFIG.suffix) {
                    scanned_code = scanned_code.slice(0, -HID_CONFIG.suffix.length);
                }

                if (scanned_code.length >= HID_CONFIG.min_length) {
                    console.log(`HID code received: ${scanned_code}`);
                    if (scan_commit_timer) clearTimeout(scan_commit_timer);
                    fast_keys = [];
                }
            }
        }
        window.addEventListener("keypress", (e) => {
            const now_ms = Date.now();
            if (now_ms - last_key_time_ms > HID_CONFIG.minimum_rate_limit_ms || document.activeElement.tagName == "INPUT" || document.activeElement.tagName == "TEXTAREA") {
                fast_keys = [];
            }
            last_key_time_ms = now_ms;
            if (e.key === "Enter") {
                fast_keys.push("\n");
                commit_hid_code();
                e.stopPropagation();
                e.preventDefault();
            } else {
                fast_keys.push(e.key);
                if (scan_commit_timer) clearTimeout(scan_commit_timer);
                if (fast_keys.length >= HID_CONFIG.min_length) {
                    scan_commit_timer = setTimeout(commit_hid_code, HID_CONFIG.minimum_rate_limit_ms);
                    e.stopPropagation();
                    e.preventDefault();
                }
            }
        })
    }
}
