import { Route } from "@/components/Route";
import { Flex, Select } from "antd";
import { Component } from "react";

import { PageHeader } from "@/components/Layouts";
import { ScanLogsIndex } from ".";

export class ScanLogsRoute extends Component {
    render() {
        return <>
            <Flex vertical gap={16}>
                <PageHeader title="Scan Logs">
                    <Select style={{ minWidth: "200px", flex: 1 }}></Select>
                </PageHeader>

                <Route exact path="/" element={<ScanLogsIndex />} />

                <Route path="/:scanner_id">
                </Route>
            </Flex>
        </>
    }
}
