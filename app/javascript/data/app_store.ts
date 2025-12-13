import type { useAppProps } from "antd/es/app/context";
import { action, computed, observable, reaction } from "mobx";
import React from "react";

export class AppStore {
    static Context = React.createContext(new AppStore());

    static instance = new AppStore();

    constructor() {
        window.addEventListener("resize", action(() => {
            this.refreshWindowHeight();
        }));
        this.refreshWindowHeight();

        reaction(() => this.isSmallDevice, (isSmallDevice) => {
            this.sidebarCollapsed = isSmallDevice;
        }, { fireImmediately: true });
    }

    ant: useAppProps;

    @observable accessor sidebarCollapsed = false;
    @observable accessor isSmallDevice = false;

    @action refreshWindowHeight() {
        this.isSmallDevice = window.innerWidth < 550;
    }

    @computed get isCompactNavBar() {
        return !this.isSmallDevice && this.sidebarCollapsed;
    }
}
