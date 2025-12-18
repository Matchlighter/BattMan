import { Avatar, Breadcrumb, Button, Collapse, Divider, Flex, Input, Typography } from "antd";
import { computed, observable } from "mobx";
import React, { Component, useLayoutEffect } from "react";

import { Box, Content } from "@/components/Basics";
import { Icon } from "@/components/Icon";
import { Thing } from "@/data/thing";

export class ThingShowRoute extends Component {
    @observable.ref accessor thing: Thing = {
        id: "DEV-A1X-5",
        // icon: "/logo.png",
        serial_number: "ABC-123",
        Device: true,
        implements: [
            { id: "MANKS-0001", product: true, name: "Manks FiBee Light Switch" },
            { id: "Device", name: "Device" },
        ]
    };

    @computed get thing_type() {
        return this.thing.implements?.find(x => this.thing[x.id]);
    }

    @computed get micro_titles() {
        const t = this.thing;
        const bits = [];

        // Indicate the Type (the first Template that it implements) of this Thing
        // TODO This may not always be reddilly available, unless we flatten the `implements:` data
        bits.push(this.thing_type?.name);

        // Indicate the Thing's ID
        bits.push(t.id); // TODO Clicking should open label generator

        // Show the Product Name if the Thing is an instance of a Product
        bits.push(this.thing.implements?.find(x => x.product)?.name);

        // Show the Serial Number if it's not part of the ID
        const sn = this.thing.serial_number;
        if (sn || !t.id?.includes(sn)) {
            bits.push(`S/N: ${sn}`);
        }

        return bits.filter(x => !!x);
    }

    render() {
        return <>
            <Flex vertical gap={16}>
                <FadingGlassHeader>
                    <Flex align="center" gap={16}>
                        <div style={{ marginLeft: "8px" }}>
                            <ThingIcon thing={this.thing} />
                        </div>
                        <div style={{ alignSelf: "stretch", flex: 1, overflow: "hidden", whiteSpace: "nowrap" }}>
                            <Breadcrumb>
                                <Breadcrumb.Item>Lariat</Breadcrumb.Item>
                                <Breadcrumb.Item>Garage</Breadcrumb.Item>
                                <Breadcrumb.Item>Shelf 1</Breadcrumb.Item>
                            </Breadcrumb>
                            <Typography.Title level={2} style={{ margin: 0, fontWeight: "lighter", overflow: "hidden", textOverflow: "ellipsis" }}>
                                Something on that Shelf
                            </Typography.Title>
                            <MicroTitles bits={this.micro_titles} />
                        </div>
                        <div style={{ alignSelf: "start" }}>
                            <Button size="large" icon={<Icon icon="edit" />}></Button>
                        </div>
                    </Flex>
                </FadingGlassHeader>

                <Pane title="Basic Info" defaultOpened>
                    <Content unpadded-v>
                        <Typography.Text strong>Category</Typography.Text>
                        <br />
                        <Typography.Text>Electronics</Typography.Text>
                        <Typography.Text strong>Location</Typography.Text>
                    </Content>
                </Pane>

                <Pane title="Custom Tags">
                    <Content>
                    </Content>
                </Pane>

                <Pane title="Attachments">
                    <Content>
                    </Content>
                </Pane>

                <Pane title="Purchase Info">
                    <Content>
                    </Content>
                </Pane>

                <Pane title="Warranty">
                    <Content>
                    </Content>
                </Pane>

                <Pane title="Sale Info">
                    <Content>
                    </Content>
                </Pane>

                <Box style={{ height: "2000px" }}>
                    Hello World
                    <Input variant="filled" />
                </Box>
            </Flex>
        </>
    }
}

const FadingGlassHeader = ({ children }: { children: React.ReactNode }) => {
    const outerRef = React.useRef<HTMLDivElement>(null);
    const innerRef = React.useRef<HTMLDivElement>(null);

    useLayoutEffect(() => {
        const outer = outerRef.current;
        const inner = innerRef.current;
        outer.style.setProperty("--sticky-inner-height", `${inner?.offsetHeight || 0}px`)
    });

    return <div className="sub-header-fancy sticky glass" ref={outerRef}>
        <div className="backdrop" />
        {/* <div className="edge" /> */}
        <div className="bottom-edge" />
        {/* <div className="backdrop-edge" /> */}
        <div className="inner" ref={innerRef}>
            {children}
        </div>
    </div>
}

const ThingIcon = ({ thing }: { thing: Thing }) => {
    let icon = thing.icon || "package_2";

    if (!thing.icon || thing.icon.includes("/")) {
        return <Avatar size={64} src={thing.icon}>
            <Icon icon="package_2" style={{ fontSize: "40px" }} />
        </Avatar>
    } else {
        return <Avatar size={64}>
            <Icon icon={icon as any} style={{ fontSize: "40px" }} />
        </Avatar>
    }
}

const Pane = ({ title, children, defaultOpened, opened }: { title: React.ReactNode, children?: React.ReactNode, defaultOpened?: boolean, opened?: boolean }) => {
    const activeKey = opened ? ["1"] : opened != null ? [] : undefined;
    return <>
        <Collapse bordered={false} className="pane" activeKey={activeKey} defaultActiveKey={defaultOpened ? "1" : undefined}>
            <Collapse.Panel header={title} key="1">
                {children}
            </Collapse.Panel>
        </Collapse>
    </>
}

const MicroTitles = (props: { bits: string[] }) => {
    return <div className="micro-text" style={{ textOverflow: "ellipsis", overflow: "hidden" }}>
        {props.bits.map((bit, idx) => <>
            {idx > 0 && <Divider key={`div-${idx}`} vertical />}
            <span style={{ whiteSpace: "nowrap" }} key={`bit-${idx}`}>{bit}</span>
        </>)}
    </div>
}
