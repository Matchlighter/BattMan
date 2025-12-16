import { PageHeader } from "@/components/Layouts";
import { Flex } from "antd";
import { Component } from "react";

export class SettingsRoute extends Component {
    render() {
        return <>
            <Flex vertical gap={16}>
                <PageHeader title="Settings" />
            </Flex>
        </>
    }
}
