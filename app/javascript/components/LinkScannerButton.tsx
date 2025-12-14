import { App, Breadcrumb, Button, Divider, Flex, Popover, QRCode, Select, Space, Switch } from "antd";
import { observer } from "mobx-react";
import { Component } from "react";
import { MdBarcodeReader } from "react-icons/md";
import { DisconnectOutlined } from "@ant-design/icons";

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
                <Flex align="center" vertical gap={8}>
                    <Select
                        style={{ alignSelf: "stretch" }}
                        showSearch={{
                            optionFilterProp: 'label',
                            filterSort: (optionA, optionB) =>
                                (optionA?.label ?? '').toLowerCase().localeCompare((optionB?.label ?? '').toLowerCase()),
                        }}
                        placeholder="Select Scanner"
                        options={[
                            {
                                value: 'A403A6E5',
                                label: 'A403A6E5',
                            },
                        ]}
                        onSelect={(_, option) => {
                            this.store.linkScanner(option.value as string);
                        }}
                    />

                    <Divider style={{ margin: 0, fontSize: "0.65rem" }} plain>Or Scan</Divider>

                    <QRCode value={`BATTMAN:CLIENT:${this.store.client_uid}:LINK`}
                        color="black"
                        bgColor="white"
                    />
                </Flex>
            </>
        }
        return <>
            <Button color="default" variant="text" style={{ position: "absolute", top: "4px", right: "4px" }} size="small"
                onClick={this.store.unlinkScanner}
            >
                <DisconnectOutlined />
            </Button>

            <Flex style={{ width: "180px" }} vertical gap={8}>
                <Flex vertical align="center">
                    <div style={{ fontSize: "0.65rem" }}>Observing</div>
                    <pre style={{ margin: 0 }}>{this.store.paired_scanner_id}</pre>
                </Flex>

                <Divider style={{ margin: 0, fontSize: "0.65rem" }} plain>Context</Divider>

                <Breadcrumb style={{ alignSelf: "center" }} styles={{ root: { justifyContent: "center" } }}>
                    <Breadcrumb.Item>Garage</Breadcrumb.Item>
                    <Breadcrumb.Item>Shelf 1</Breadcrumb.Item>
                    <Breadcrumb.Item>Bin A</Breadcrumb.Item>
                    <Breadcrumb.Item>Thing X</Breadcrumb.Item>
                </Breadcrumb>

                <Divider style={{ margin: 0, fontSize: "0.65rem" }} plain>Options</Divider>

                <Flex>
                    <Flex style={{ flex: 1 }} gap="4px" vertical align="center" title={`When a text field is selected in the UI, prevent default scanner behavior and instead populate the text field directly.`}>
                        <Switch />
                        <div>Autofill</div>
                    </Flex>
                    <Flex style={{ flex: 1 }} gap="4px" vertical align="center" title={`Navigate to the relevant item page when a scanned barcode is recognized.`}>
                        <Switch />
                        <div>Follow</div>
                    </Flex>
                </Flex>

                <Divider style={{ margin: 0, fontSize: "0.65rem" }} plain>Actions</Divider>

                <Button>
                    Scanner Logs
                </Button>
            </Flex>
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
