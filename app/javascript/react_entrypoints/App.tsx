import React, { lazy, Suspense } from "react";
import axios, { Axios } from "axios"
import { BrowserRouter, Routes } from "react-router-dom";

import { config } from "@matchlighter/fetcher"
import { ProvideBlocks } from "@matchlighter/common_library/components/Block";

import "material-symbols";
import "@/screen.less";

import "@/cable";

import { AppLayout } from "@/components/AppLayout.ant";
import { Route } from "@/components/Route";
import { AppStore } from "@/data/app_store";

config.api.backend = new Axios({
    ...axios.defaults,
    baseURL: "/api/v1/",
    headers: {
        "Content-Type": "application/json",
        'Accept': "application/json",
    },
    withCredentials: true,
})

const ScanLogsRoute = lazy(() => import("@/routes/scan_logs/route"));
const ScannersRoutes = lazy(() => import("@/routes/scanners/routes"));
const SettingsRoute = lazy(() => import("@/routes/settings/route"));
const ThingsRoutes = lazy(() => import("@/routes/things/Routes"));

export default class App extends React.Component {
    render() {
        return <>
            <ProvideBlocks>
                <AppStore.Context.Provider value={AppStore.instance}>
                    <BrowserRouter>
                        <AppLayout>
                            <Suspense>
                                <Routes>
                                    <Route path="/things/*" element={<ThingsRoutes />} />
                                    <Route path="/scan-logs/*" element={<ScanLogsRoute />} />
                                    <Route path="/settings/*" element={<SettingsRoute />} />
                                    <Route path="/scanners/*" element={<ScannersRoutes />} />
                                    {/* <Route path="/scan" element={<MobileScanner />} /> */}
                                    <Route path="*" element={<>Not Found</>} />
                                </Routes>
                            </Suspense>
                        </AppLayout>
                    </BrowserRouter>
                </AppStore.Context.Provider>
            </ProvideBlocks>
        </>
    }
}
