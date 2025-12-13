import { App, Button, Popover, QRCode } from "antd";
import { observer } from "mobx-react";
import { Component } from "react";
import { MdBarcodeReader } from "react-icons/md";

import { observerMethod } from "@matchlighter/common_library/decorators/method_component"
import { with_meta_components, context } from "@matchlighter/meta_components"

import { AppStore } from "@/data/app_store";
import { computed } from "mobx";

@with_meta_components
@observer
export class LinkScannerButton extends Component {
    @context(AppStore.Context) accessor store: AppStore;

    @computed get isLinked() {
        return !!this.store.paired_scanner_id;
    }

    @observerMethod renderPopover() {
        if (!this.isLinked) {
            return <>
                <QRCode value={`BATTMAN:CLIENT:${this.store.client_uid}`}
                    color="black"
                    bgColor="white"
                />
            </>
        }
        return <>
            Paired to: {this.store.paired_scanner_id}
        </>
    }

    render() {
        return <>
            <Popover content={<this.renderPopover />} trigger="click">
                <Button type={this.isLinked ? "primary" : "default"} title="Link barcode scanner">
                    <MdBarcodeReader />
                </Button>
            </Popover>
        </>
    }
}
