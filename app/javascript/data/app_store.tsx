import { Subscription } from "@rails/actioncable";
import type { useAppProps } from "antd/es/app/context";
import { action, computed, observable, reaction, runInAction } from "mobx";
import React from "react";

import { CABLE, Message } from "@/cable";
import { ScanHookStore } from "./scan_hooking";
import { ClientCodesStore } from "./client_codes";

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
                this.client_codes_store.handleCodeScanned(data.payload,data.scanner_id);
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
}
