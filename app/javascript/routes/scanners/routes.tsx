import { Route } from "@/components/Route";
import { ScannerOnboardRoute } from "./onboard";
import { Routes } from "react-router";

export default () => <Routes>
    <Route index element={<div>Scanners Index</div>} />
    <Route path="/onboard/" element={<ScannerOnboardRoute />} />
</Routes>
