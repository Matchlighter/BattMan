import React from "react";

import "@/screen.less";
import "material-symbols";

import "@/cable";
import { CABLE } from "@/cable";
import { getClientUid } from "@/data/common";

const u = new URL(window.location.toString());
const linkStr = u.searchParams.get('link') || '';
const introducer_id = linkStr.split(':')[2];

const sub = CABLE.subscriptions.create({
    channel: "MobileScannerChannel",
    introducer_id: introducer_id,
    scanner_id: `WEB:${getClientUid()}`,
}, {
    connected() {
        sub.perform("scan", { payload: linkStr });
    }
});


export default class MobileScanner extends React.Component {
    render() {
        return <>
            This will be super-minimal - button to do a scan, toogle for continuous mode, and log of recent scans.
        </>
    }
}
