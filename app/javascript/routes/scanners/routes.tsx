import { Route } from "@/components/Route";
import { ScannerOnboardRoute } from "./onboard";

export const ScannersRoutes = () => <>
    <Route exact path="/" element={<div>Scanners Index</div>} />
    <Route path="/onboard/" element={<ScannerOnboardRoute />} />
</>
