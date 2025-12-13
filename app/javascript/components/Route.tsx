import React from "react";
import { RouteProps, Route as RRRoute, useRouteMatch } from "react-router-dom";

import { url } from "@matchlighter/common_library/lib/strings";

export const Route = (props: RouteProps & { element?: React.ReactElement, absolute?: boolean, keyOn?: "match" }) => {
    const match = useRouteMatch();
    const { element, absolute, ...rest } = props;

    if (!absolute && match) {
        rest.path = url`${match.path}/${rest.path as string || ""}`.replace(/\/+/g, '/');
    }

    if (element) {
        rest.render = (m) => {
            let key;
            if (props.keyOn == "match") {
                key = m.match.url
            }
            return React.cloneElement(element, { ...m, key, });
        }
    }

    return <RRRoute {...rest} />
}
