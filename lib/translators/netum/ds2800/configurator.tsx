import { Component } from "react";

export default class DS2800Configurator extends Component {
    render() {
        return <>
            <p>This is the configuration component for the DS2800 scanner.</p>
            <div>Connect to WiFi</div>
            <div>Set Scanning Options</div>
            <div>Connect to MQTT -or- Configure HTTP</div>
        </>
    }
}
