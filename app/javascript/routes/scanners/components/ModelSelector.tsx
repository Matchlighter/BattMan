import { Cascader, Divider, Spin } from "antd";
import { action, computed, observable } from "mobx";
import { observer } from "mobx-react";
import { Component } from "react";

import { api_fetched } from "@matchlighter/fetcher";
import { with_meta_components } from "@matchlighter/meta_components";

import { Icon } from "@/components/Icon";

@with_meta_components
@observer
export class ModelSelector extends Component<{ onModelSelected?: (model: string, mdata) => void }> {
    @api_fetched("scanners/known_models")
    @observable.ref accessor known_models!: any[];

    @computed get options() {
        if (!this.known_models) return [];
        const byKey: Record<string, any> = {};
        const root = { children: [] };

        const getOption = (key: string) => {
            if (byKey[key]) return byKey[key];
            const split_key = key.split("/").map(s => s.trim());
            const last = split_key.pop()!;
            const rest = split_key.join("/");

            const parent = rest ? getOption(rest) : root;
            const opt = {
                value: key,
                label: last,
                children: [],
            };
            parent.children.push(opt);
            byKey[key] = opt;
            return opt;
        }

        for (const [key, model] of Object.entries(this.known_models)) {
            getOption(key);
        }

        return Object.values(root.children);
    }

    @observable.ref accessor selectedOptions;
    @action.bound handleModelSelect(selectedOptions: any[]) {
        this.selectedOptions = selectedOptions
        const selected = selectedOptions[selectedOptions.length - 1];

        const mdata = this.known_models?.[selected];
        this.props.onModelSelected?.(selected, mdata);
    }

    @action.bound handleClear() {
        this.selectedOptions = [];
        this.props.onModelSelected?.(null, null);
    }

    render() {
        const isLoaded = !!this.known_models;
        return <>
            <Cascader
                suffix={!isLoaded && <Spin style={{ fontSize: "20px", display: "inline-flex" }} indicator={<Icon className="spinner" icon="progress_activity" />} />}
                size="large"
                style={{ width: "100%", maxWidth: "400px" }}
                options={this.options}
                popupRender={popupRender}
                onChange={this.handleModelSelect}
                onClear={this.handleClear}
                popupMatchSelectWidth
                showSearch
                classNames={{
                    content: "ant-select-centered",
                }}
                styles={{
                    input: {
                        textAlign: "center",
                        width: "100%",
                    }
                }}
            />
        </>
    }
}


interface Option {
    value: string;
    label: string;
    children?: Option[];
}

const popupRender = (menus: React.ReactNode) => (
    <div>
        {menus}
        <Divider style={{ margin: 0 }} />
        <div style={{ padding: 8, textAlign: "right", fontSize: "0.75rem" }}>
            <a href="#">Can't find yours?</a>
        </div>
    </div>
);
