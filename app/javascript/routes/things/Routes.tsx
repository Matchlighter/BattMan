import { Route } from "@/components/Route"
import { ThingShowRoute } from "./Show"

export const ThingsRoutes = () => {
    return <>
        <Route path=":id" element={<ThingShowRoute />} />
    </>
}