import { Component } from "react";

export default class GenericConfigurator extends Component<{ selected_model: string }> {
    render() {
        return <>
            <p>Selected Model: {this.props.selected_model}</p>
            <p>Configure Scanner to send data to BattMan's generic HTTP or MQTT endpoints:</p>
            {/* TODO */}
        </>
    }
}
