import { Card, Col, Empty, Row, Statistic, Typography } from "antd";
import { Component } from "react";

import { Box } from "@/components/Basics";

export class ScanLogsIndex extends Component {
    render() {
        return <>
            <Row gutter={16}>
                <Col span={12}>
                    <Card variant="borderless">
                        <Statistic
                            title="Active"
                            value={11.28}
                            precision={2}
                            styles={{ content: { color: '#3f8600' } }}
                            // prefix={<ArrowUpOutlined />}
                            suffix="%"
                        />
                    </Card>
                </Col>
                <Col span={12}>
                    <Card variant="borderless">
                        <Statistic
                            title="Idle"
                            value={9.3}
                            precision={2}
                            styles={{ content: { color: '#cf1322' } }}
                            // prefix={<ArrowDownOutlined />}
                            suffix="%"
                        />
                    </Card>
                </Col>
            </Row>

            <Box>
                <Empty description={null} image={Empty.PRESENTED_IMAGE_SIMPLE}>
                    <Typography.Text>No scanners linked yet</Typography.Text>
                </Empty>
            </Box>
        </>
    }
}
