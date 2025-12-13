import React from "react";
import { BrowserRouter } from "react-router-dom";

import "@/bootstrap";
import "@/screen.less";

import { AppLayout } from "@/components/AppLayout.ant";
import { AppStore } from "@/data/app_store";

export default class App extends React.Component {
    store = new AppStore();
    render() {
        return <>
            <AppStore.Context.Provider value={this.store}>
                <BrowserRouter>
                    <AppLayout>

                    </AppLayout>
                </BrowserRouter>
            </AppStore.Context.Provider>
        </>
    }
}
