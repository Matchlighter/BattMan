import { Breadcrumb, Button, Divider, Flex, Popover, Select, Switch, Typography } from "antd";
import { computed } from "mobx";
import { observer } from "mobx-react";
import { Component } from "react";
import { useNavigate } from "react-router";

import { BoundField } from "@matchlighter/cognizant_forms/components";
import { observerMethod } from "@matchlighter/common_library/decorators/method_component";
import { context, hook, with_meta_components } from "@matchlighter/meta_components";

import { AppStore } from "@/data/app_store";
import { QR } from "./ClientQR";
import { Icon } from "./Icon";

@with_meta_components
@observer
export class LinkScannerButton extends Component {
    @context(AppStore.Context) accessor store: AppStore;
    @hook(useNavigate) accessor navigate: ReturnType<typeof useNavigate>;

    @computed get isLinked() {
        return !!this.store.paired_scanner_id;
    }

    @computed get mobileScannerURL() {
        const u = new URL(window.location.toString());
        u.pathname = `/mobile_scanner/`;
        // Including the full BATTMAN:CLIENT token here allows this QR to be dual-purpose:
        //   It can be scanned my a wireless scanner, or by a phone
        u.searchParams.set('link', `BATTMAN:CLIENT:${this.store.client_conn_uid}:LINK`);
        // TODO Include an auth token
        return u.toString();
    }

    @observerMethod renderPopover() {
        const emulated = this.store.isInEmulationMode;
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
                        value={null}
                        placeholder="Select Scanner"
                        options={[
                            {
                                value: 'A403A6E5',
                                label: 'A403A6E5',
                            },
                            {
                                value: '_local_',
                                label: 'Camera/HID',
                            },
                            {
                                value: '_new_',
                                label: 'Connect New',
                            },
                        ]}
                        onSelect={(_, option) => {
                            if (option.value == '_new_') {
                                this.navigate('/scanners/onboard/');
                                // TODO: Close popover
                            } else if (option.value == '_local_') {
                                this.store.linkScanner(this.store.emulatedScannerID);
                            } else {
                                this.store.linkScanner(option.value as string);
                            }
                        }}
                    />

                    <Divider style={{ margin: 0, fontSize: "0.65rem" }} plain>Or Scan</Divider>

                    <QR value={this.mobileScannerURL} />
                </Flex>
            </>
        } else {
            return <>
                <Button color="default" variant="text" style={{ position: "absolute", top: "4px", right: "4px" }} size="small"
                    onClick={this.store.unlinkScanner}
                >
                    <Icon icon="link_off" />
                </Button>

                <Flex style={{ width: "180px" }} vertical gap={8}>
                    {emulated ?
                        <>
                            <Flex vertical align="center">
                                <div style={{ fontSize: "0.65rem" }}>Camera/HID Scanner</div>
                            </Flex>

                            <Flex align="center" justify="center" gap={12}>
                                <Button variant="solid" size="large" icon={<Icon icon="barcode_scanner" />} />
                                <div style={{ flex: "2", fontSize: "0.75rem" }}>
                                    <div>Use a HID scanner</div>
                                    <div>Or click to use camera</div>
                                </div>
                            </Flex>
                        </> : <>
                            <Flex vertical align="center">
                                <div style={{ fontSize: "0.65rem" }}>Observing</div>
                                <pre style={{ margin: 0 }}>{this.store.paired_scanner_id}</pre>
                            </Flex>
                        </>
                    }

                    <Divider style={{ margin: 0, fontSize: "0.65rem" }} plain>Context</Divider>

                    <Breadcrumb style={{ alignSelf: "center" }} styles={{ root: { justifyContent: "center" } }}>
                        <Breadcrumb.Item>Garage</Breadcrumb.Item>
                        <Breadcrumb.Item>Shelf 1</Breadcrumb.Item>
                        <Breadcrumb.Item>Bin A</Breadcrumb.Item>
                        <Breadcrumb.Item>Thing X</Breadcrumb.Item>
                    </Breadcrumb>

                    <Divider style={{ margin: 0, fontSize: "0.65rem" }} plain>Options</Divider>

                    <Flex>
                        {!emulated && <Flex style={{ flex: 1 }} gap="4px" vertical align="center" title={`When a text field is selected in the UI, prevent default scanner behavior and instead populate the text field directly.`}>
                            <BoundField store={this.store.scan_hook_store} name="autofill_enabled">
                                <Switch />
                            </BoundField>
                            <div>Autofill</div>
                        </Flex>}
                        <Flex style={{ flex: 1 }} gap="4px" vertical align="center" title={`Navigate to the relevant thing page when a scanned barcode is recognized.`}>
                            <BoundField store={this.store} name="follow_scans">
                                <Switch />
                            </BoundField>
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
    }

    render() {
        return <>
            <Popover content={<this.renderPopover />} trigger="click">
                <Button type={this.isLinked ? "primary" : "default"} title="Link barcode scanner">
                    <Icon icon="barcode_reader" />
                </Button>
            </Popover>
        </>
    }
}
