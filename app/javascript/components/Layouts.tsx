import { Flex, Typography } from "antd"

export const PageHeader = (props: { title: React.ReactNode, children?: React.ReactNode }) => {
    return <Flex gap={12} wrap="wrap" align="center">
        <Typography.Title level={2} style={{ margin: 0, flex: 3, whiteSpace: "nowrap", fontSize: "1.7rem" }}>{props.title}</Typography.Title>
        <div style={{ flex: "1 0", display: "flex", justifyContent: "flex-end" }}>
            {props.children}
        </div>
    </Flex>
}

export const FixedHeaderPageLayout = ({ header, children }: { header: React.ReactNode, children?: React.ReactNode }) => {
    if (typeof header === "string") {
        header = <PageHeader title={header} />
    }
    return <>
        <Flex vertical gap={16} style={{ height: "100%" }}>
            {header}
            <div style={{ overflow: "auto" }}>
                {children}
            </div>
        </Flex>
    </>
}
