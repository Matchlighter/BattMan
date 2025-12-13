import React from "react";
import { BrowserRouter } from "react-router-dom";

import "@/bootstrap";
import "@/screen.less";

import "@/cable";

import { AppLayout } from "@/components/AppLayout.ant";
import { AppStore } from "@/data/app_store";

export default class App extends React.Component {
    render() {
        return <>
            <AppStore.Context.Provider value={AppStore.instance}>
                <BrowserRouter>
                    <AppLayout>

                    </AppLayout>
                </BrowserRouter>
            </AppStore.Context.Provider>
        </>
    }
}
