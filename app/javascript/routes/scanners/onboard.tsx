import { Button, Divider, Flex, Result, Steps, Typography } from "antd";
import classNames from "classnames";
import { action, computed, observable, runInAction } from "mobx";
import { observer } from "mobx-react";
import { Component } from "react";

import { observerMethod } from "@matchlighter/common_library/lib/decorators/method_component";
import { context, with_meta_components } from "@matchlighter/meta_components";

import { Box } from "@/components/Basics";
import { ClientCallbackQR } from "@/components/ClientQR";
import { Icon } from "@/components/Icon";
import { FixedHeaderPageLayout } from "@/components/Layouts";
import { pluralize } from "@/components/Plural";
import { AppStore } from "@/data/app_store";
import { ModelSelector } from "./components/ModelSelector";

@with_meta_components
@observer
export class ScannerOnboardRoute extends Component {
    @context(AppStore.Context) accessor store: AppStore;

    @observable.ref accessor selectedModel: string;
    @observable.ref accessor selectedModelConfig;
    @observable.ref accessor configurationComponent;

    @observable accessor currentStep: "configure" | "test" | "done" = "configure";

    @action.bound async handleModelSelected(model: string, mdata) {
        if (model === this.selectedModel) return;

        this.selectedModel = model;
        this.selectedModelConfig = mdata;
        this.configurationComponent = mdata?.config_component || null;
        this.configurationComponent = null;

        this.currentStep = "configure";

        // @ts-ignore
        document.activeElement?.blur();

        if (this.selectedModel) {
            try {
                const Comp = await import(/* webpackInclude: /\.[jt]sx$/ */ `@lib/translators/${mdata.url_base}/configurator`);
                runInAction(() => {
                    this.configurationComponent = <Comp.default selected_model={this.selectedModel} />;
                });
            } catch (e) {
                console.error("Failed to load configurator component:", e);
                runInAction(() => {
                    this.currentStep = "test";
                })
            }
        }
    }

    @action.bound handleProceedToTest() {
        this.currentStep = "test";
    }

    @action.bound handleResetOnboarding() {
        this.selectedModel = null;
        this.selectedModelConfig = null;
        this.configurationComponent = null;
        this.currentStep = "configure";
        this.seenScanners = [];
        this.seenScannersMeta = {};
    }

    @computed get currentStepIndex() {
        if (this.currentStep === "configure") {
            if (!this.selectedModel) return 0;
            return 1;
        }
        if (this.currentStep === "test") return 2;
        if (this.currentStep === "done") return 3;
        return 0;
    }

    @observerMethod
    renderStepsList() {
        return <Steps
            titlePlacement="vertical"
            current={this.currentStepIndex}
            percent={60}
            orientation="vertical"
            style={{ maxWidth: "300px" }}
            items={[
                {
                    title: 'Select Model',
                    content: "Find your scanner model",
                    icon: <Icon icon="barcode_reader" />,
                },
                {
                    title: 'Configure',
                    content: "Configure your scanner to connect to BattMan",
                    icon: <Icon icon="settings" />,
                },
                {
                    title: 'Test Connection',
                    content: "Check if BattMan is receiving data from your scanner",
                    icon: <Icon icon="science" />,
                },
                {
                    title: 'Done',
                    content: "Have some beeping fun!",
                    icon: <Icon icon="check_circle" />,
                },
            ]}
        />
    }

    @observerMethod
    renderCurrentStep() {
        if (this.currentStep == "done") {
            return <>
                <Box style={{ flex: 1 }}>
                    <Result
                        status="success"
                        title={`${pluralize("Scanner", this.seenScanners.length, true)} Onboarded Successfully!`}
                        subTitle="Go have some beeping fun"
                        extra={[
                            <Button onClick={this.handleResetOnboarding}>Onboard Another</Button>,
                        ]}
                    />
                </Box>
            </>
        }

        return <>
            <Box
                className={classNames("step-box", { "previous-step": !!this.selectedModel })}
                style={{ flex: 1, textAlign: "center" }}
            >
                <Typography.Title level={4} style={{ marginTop: 0 }}>
                    Select your Scanner Model
                </Typography.Title>
                <ModelSelector onModelSelected={this.handleModelSelected} />
            </Box>

            {this.selectedModel && <Box
                className={classNames("step-box", { "previous-step": this.currentStep !== "configure" })}
                style={{ flex: 1, }}
            >
                <Typography.Title level={4} style={{ margin: 0, textAlign: "center" }}>
                    Configure your Scanner
                </Typography.Title>

                {this.configurationComponent}

                {this.currentStep === "configure" && <Flex justify="end">
                    <Button type="primary" onClick={this.handleProceedToTest}>
                        Next
                    </Button>
                </Flex>}
            </Box>}

            {this.currentStep === "test" && <Box style={{ flex: 1, textAlign: "center" }}>
                <Typography.Title level={4} style={{ margin: 0 }}>
                    Test the Configuration
                </Typography.Title>
                <this.renderScannerTestBox />
            </Box>}
        </>
    }

    @observable.shallow accessor seenScanners = [];
    @observable accessor seenScannersMeta: Record<string, any> = {};

    @action.bound handleQRScanned(scanner: any) {
        this.seenScanners = this.seenScanners.filter(s => s != scanner);
        this.seenScanners.unshift(scanner);
        this.seenScannersMeta[scanner] ||= { count: 0 };
        this.seenScannersMeta[scanner]["scanner"] = scanner;
        this.seenScannersMeta[scanner]["count"] += 1;
    }

    @observerMethod renderScannerTestBox() {
        return <Flex wrap="wrap" gap={6} style={{ marginTop: "16px", maxWidth: "600px", display: "inline-flex" }}>
            <ClientCallbackQR callback={this.handleQRScanned} style={{ alignSelf: "center", flexShrink: 0 }} />
            <Divider vertical style={{ alignSelf: "stretch", height: "unset" }} />
            <Flex justify="start" align="center" style={{ maxWidth: "450px", textAlign: "left", minWidth: "250px", flex: 1 }}>
                {this.seenScanners.length > 0 ? (
                    <Flex vertical gap={8} style={{ width: "100%" }}>
                        <Typography.Text>
                            Successfully received data from the following {pluralize("scanner", this.seenScanners.length)}:
                        </Typography.Text>
                        <ul style={{ marginTop: 0 }}>
                            {this.seenScanners.map((scanner, idx) => {
                                const meta = this.seenScannersMeta[scanner];
                                let line = scanner;
                                if (meta.count > 1) {
                                    line += ` (${meta.count}x)`;
                                }
                                return <li key={scanner}>
                                    <Typography.Text>
                                        {line}
                                    </Typography.Text>
                                </li>
                            })}
                        </ul>
                        <Button type="primary" onClick={() => this.currentStep = "done"}>
                            Finish Onboarding
                        </Button>
                    </Flex>
                ) : (
                    <Typography.Text>
                        Scan the QR code with your scanner(s) to complete onboarding.
                        If everything's working, you should see your scanner(s) appear here.
                        You can continue to reference or repeat configuration steps above if necessary.
                    </Typography.Text>
                )}
            </Flex>
        </Flex>
    }

    render() {
        return <>
            <FixedHeaderPageLayout header="Onboard Scanner">
                <Flex gap={16} wrap="wrap-reverse" justify="stretch" align="start">
                    <Box style={{ flex: "1 0", minWidth: "300px", position: "sticky", top: "0px" }}>
                        <this.renderStepsList />
                    </Box>
                    <Flex vertical gap={16} style={{ flex: "3 0", overflow: "auto", minWidth: "300px" }}>
                        <this.renderCurrentStep />
                    </Flex>
                </Flex>
            </FixedHeaderPageLayout>
        </>
    }
}
