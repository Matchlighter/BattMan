import { action } from "mobx";
import { observer } from "mobx-react";
import { useContext } from "react";
import { useHistory, useLocation } from "react-router";

import { MdBarcodeReader, MdDevices, MdLocationPin, MdMicrowave, MdOutlineCameraAlt, MdShoppingCart } from "react-icons/md";

import {
    ClusterOutlined,
    LayoutOutlined,
    MenuFoldOutlined,
    MenuUnfoldOutlined,
    SettingOutlined
} from '@ant-design/icons';
import { Button, ConfigProvider, Drawer, Flex, Input, Layout, Menu, theme } from 'antd';
import type { ItemType, MenuItemType } from "antd/es/menu/interface";

import { dft } from "@matchlighter/common_library/data/traversal";

import { AppStore } from "@/data/app_store";
import "./screen.ant.less";

const { Header, Sider, Content } = Layout;

const MENU_ITEMS: ItemType<MenuItemType>[] = [
    {
        key: '/locations',
        icon: <MdLocationPin />,
        label: 'Locations',
    },
    {
        key: '/items',
        icon: <ClusterOutlined />,
        label: 'Items',
        children: [
            {
                key: '/items/devices',
                icon: <MdDevices />,
                label: 'Devices',
            },
            {
                key: '/items/appliances',
                icon: <MdMicrowave />,
                label: 'Appliances',
            },
        ]
    },
    {
        key: '/products',
        icon: <MdShoppingCart />,
        label: 'Products',
    },
    {
        key: '/templates',
        icon: <LayoutOutlined />,
        label: 'Templates',
    },
    {
        key: '/settings',
        icon: <SettingOutlined />,
        label: 'Settings',
    },
];

const ALL_KEYS: string[] = [];
dft(MENU_ITEMS, (node) => {
    ALL_KEYS.push(node.key as string);
    return node.children || [];
});

const AppMenu = observer(() => {
    const history = useHistory();
    const location = useLocation();

    const selectedKeys = ALL_KEYS.filter(key => location.pathname.startsWith(key));

    return <>
        <Menu
            // theme="dark"
            mode="inline"
            // defaultSelectedKeys={['1']}
            selectedKeys={selectedKeys}
            onSelect={(info) => {
                history.push(info.key);
            }}
            items={MENU_ITEMS}
        />
    </>
})

const MenuBarContent = observer(() => {
    return <>
        <div className="logo-sidebar">
            <div className="logo-icon" />
            <div className="logo-logotype">
                <div title="Now for more than just batteries!" className="logo-title">BattMan</div>
                <div className="logo-subtitle">Home Inventory Management</div>
            </div>
        </div>
        <AppMenu />
        <div style={{ flexGrow: 1 }} />
    </>
});

const MenuBar = observer(() => {
    const store = useContext(AppStore.Context);

    if (store.isSmallDevice) {
        return <Drawer
            className="main-sidebar"
            closable={false}
            open={store.isSmallDevice && !store.sidebarCollapsed}
            onClose={action(() => {
                store.sidebarCollapsed = true;
            })}
            placement="left"
            size={200}
            styles={{
                body: {
                    background: "#141414",
                    padding: 0,
                }
            }}
        >
            <MenuBarContent />
        </Drawer>
    } else {
        return <Sider
            className="main-sidebar"
            trigger={null}
            theme="light"
            collapsible
            collapsed={store.isSmallDevice || store.sidebarCollapsed}
        >
            <MenuBarContent />
        </Sider>
    }
});

const InnerLayout = observer((props: { children?: React.ReactNode }) => {
    const store = useContext(AppStore.Context);

    const {
        token: { colorBgContainer, borderRadiusLG },
    } = theme.useToken();

    return <Layout style={{ height: "100vh" }}>
        <MenuBar />
        <Layout>
            <Header style={{ padding: 0, background: colorBgContainer, display: "flex" }}>
                <Button
                    type="text"
                    icon={store.sidebarCollapsed ? <MenuUnfoldOutlined /> : <MenuFoldOutlined />}
                    onClick={() => store.sidebarCollapsed = !store.sidebarCollapsed}
                    style={{
                        fontSize: '16px',
                        width: 64,
                        height: 64,
                    }}
                />
                <div style={{ flexGrow: 1 }} />
                <Flex align="center" gap="small" style={{ padding: "10px", width: "30%", maxWidth: "400px", flex: 1, minWidth: "250px" }}>
                    <Input.Search style={{}} placeholder="Search..." variant="underlined" />
                    <Button title="Scan with camera">
                        <MdOutlineCameraAlt />
                    </Button>
                    <Button title="Link barcode scanner">
                        <MdBarcodeReader />
                    </Button>
                </Flex>
            </Header>
            <Content
                style={{
                    margin: '24px 16px',
                    padding: 24,
                    minHeight: 280,
                    background: colorBgContainer,
                    borderRadius: borderRadiusLG,
                }}
            >
                {props.children}
            </Content>
        </Layout>
    </Layout>
});

export const AppLayout = observer((props: { children?: React.ReactNode }) => {
    return <>
        <ConfigProvider
            theme={{
                algorithm: theme.darkAlgorithm,
                token: {
                    // colorBgBase: "yellow",
                    colorPrimary: 'rgba(196, 171, 45, 1)',
                    // colorPrimaryBg: "red",
                },
                components: {
                    Layout: {
                        // siderBg: "#333",
                        /* here is your component tokens */
                    },
                    Menu: {
                        // darkItemBg: "#333",
                        // darkSubMenuItemBg: "#222",
                        // darkItemHoverBg: "red",
                        // darkItemSelectedBg: "red",
                    },
                },
            }}
        >
            <InnerLayout {...props} />
        </ConfigProvider>
    </>
})
