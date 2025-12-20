import { Route } from "@/components/Route"
import { ThingShowRoute } from "./Show"
import { Routes } from "react-router"

export default () => {
    return <Routes>
        <Route path=":id" element={<ThingShowRoute />} />
    </Routes>
}
