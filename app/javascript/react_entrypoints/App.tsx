import React from "react";
import { BrowserRouter } from "react-router-dom";

import { ProvideBlocks } from "@matchlighter/common_library/components/Block";

import "@/bootstrap";
import "@/cable";
import "@/screen.less";

import { AppLayout } from "@/components/AppLayout.ant";
import { Route } from "@/components/Route";
import { AppStore } from "@/data/app_store";
import { ScanLogsRoute } from "@/routes/scan_logs/route";
import { ScannersRoutes } from "@/routes/scanners/routes";
import { SettingsRoute } from "@/routes/settings/route";

export default class App extends React.Component {
    render() {
        return <>
            <ProvideBlocks>
                <AppStore.Context.Provider value={AppStore.instance}>
                    <BrowserRouter>
                        <AppLayout>
                            <Route path="/scan-logs" element={<ScanLogsRoute />} />
                            <Route path="/settings" element={<SettingsRoute />} />
                            <Route path="/scanners" element={<ScannersRoutes />} />
                        </AppLayout>
                    </BrowserRouter>
                </AppStore.Context.Provider>
            </ProvideBlocks>
        </>
    }
}
