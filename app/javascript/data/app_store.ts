import { action, observable } from "mobx";
import React from "react";

export class AppStore {
    static Context = React.createContext(new AppStore());

    constructor() {
        window.addEventListener("resize", action(() => {
            this.refreshWindowHeight();
        }));
        this.refreshWindowHeight();
    }

    @observable accessor sidebarCollapsed = false;
    @observable accessor isSmallDevice = false;

    @action refreshWindowHeight() {
        this.isSmallDevice = window.innerWidth < 500;
        this.sidebarCollapsed = this.isSmallDevice;
    }
}
