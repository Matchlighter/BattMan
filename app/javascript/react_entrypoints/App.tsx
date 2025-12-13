import React from "react";
import { BrowserRouter } from "react-router-dom";

import "@/bootstrap";
import "@/screen.less";

import "@/cable_toast";
import { AppLayout } from "@/components/AppLayout.mantine";
import { AppStore } from "@/data/app_store";
import { MantineProvider, createTheme } from "@mantine/core";

const theme = createTheme({
    primaryColor: "yellow",
})

export default class App extends React.Component {
    store = new AppStore();
    render() {
        return <>
            <AppStore.Context.Provider value={this.store}>
                <MantineProvider theme={theme} defaultColorScheme="dark">
                    <BrowserRouter>
                        <AppLayout>

                        </AppLayout>
                    </BrowserRouter>
                </MantineProvider>
            </AppStore.Context.Provider>
        </>
    }
}
