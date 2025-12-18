import cnames from "classnames";
import { observer } from "mobx-react";
import { ComponentProps, useContext } from "react";
import { useHistory, useLocation } from "react-router";

import { App, Button, ConfigProvider, Flex, Input, Layout, Menu, theme, ThemeConfig } from 'antd';

import { dft } from "@matchlighter/common_library/data/traversal";
import { UseBlock } from "@matchlighter/common_library/lib/components/Block";

import "./screen.ant.less";

import { AppStore } from "@/data/app_store";
import { Icon } from "./Icon";
import { LinkScannerButton } from "./LinkScannerButton";
import { MENU_ITEMS } from "./MenuItems";

const ALL_KEYS: string[] = [];
dft(MENU_ITEMS, (node) => {
    ALL_KEYS.push(node.key as string);
    return node.children || [];
});

const AppMenu = observer(() => {
    const history = useHistory();
    const location = useLocation();
    const store = useContext(AppStore.Context);

    const selectedKeys = ALL_KEYS.filter(key => location.pathname.startsWith(key));

    return <>
        <Menu
            mode="inline"
            selectedKeys={selectedKeys}
            onSelect={(info) => {
                history.push(info.key);
                if (store.isSmallDevice) {
                    store.sidebarCollapsed = true;
                }
            }}
            items={MENU_ITEMS}
        />
    </>
})

const MenuBar = observer(() => {
    const store = useContext(AppStore.Context);

    return <Layout.Sider
        className={cnames("main-sidebar", { "as-drawer": store.isSmallDevice, "open": !store.sidebarCollapsed })}
        trigger={null}
        theme="light"
        collapsible
        collapsed={!store.isSmallDevice && store.sidebarCollapsed}
        collapsedWidth={64}
    >
        {store.isSmallDevice && <Button
            type="text"
            icon={<Icon icon="left_panel_open" />}
            onClick={() => store.sidebarCollapsed = !store.sidebarCollapsed}
            style={{
                fontSize: '24px',
                width: 64,
                height: 64,
                position: "absolute",
                top: 0,
                right: 0,
            }}
        />}

        <div className="logo-sidebar">
            <div className="logo-icon" />
            <div className="logo-logotype">
                <div title="Now for more than just batteries!" className="logo-title">BattMan</div>
                <div className="logo-subtitle">Home Inventory Management</div>
            </div>
        </div>

        <AppMenu />

        <div style={{ flexGrow: 1 }} />
    </Layout.Sider>
});

const InnerLayout = observer((props: { children?: React.ReactNode }) => {
    const store = useContext(AppStore.Context);

    const ant_app = App.useApp();
    store.ant = ant_app;

    const {
        token: { colorBgContainer, borderRadiusLG },
    } = theme.useToken();

    const search_props: ComponentProps<typeof Input.Search> = {
        variant: "underlined",
        placeholder: "Search...",
    }

    return <Layout style={{ height: "100vh" }}>
        <MenuBar />
        <Layout>
            <Layout.Header style={{ padding: 0 }}>
                <Flex align="center" wrap="wrap-reverse" gap="small" style={{ flex: 1, }}>
                    <div>
                        <Button
                            type="text"
                            icon={store.sidebarCollapsed ? <Icon icon="left_panel_open" /> : <Icon icon="left_panel_close" />}
                            onClick={() => store.sidebarCollapsed = !store.sidebarCollapsed}
                            style={{
                                // position: "absolute",
                                fontSize: '24px',
                                width: 64,
                                height: 64,
                                display: "flex",
                            }}
                        />

                        <UseBlock block="page-title"></UseBlock>
                    </div>

                    <div style={{ lineHeight: 0, display: "flex", gap: "8px", flex: 1, justifyContent: "end", paddingRight: "10px" }}>
                        {!store.isSmallDevice && <Input.Search
                            style={{ maxWidth: "300px", flex: 1 }}
                            {...search_props}
                        />}
                        <Button title="Scan with camera">
                            <Icon icon="qr_code_scanner" />
                        </Button>
                        <LinkScannerButton />
                    </div>
                </Flex>

                {/* TODO A CSS-only solution to wrapping just the search input would be nice, but for now we use a conditional rendering */}
                {/*   The previous commit has a more CSS-based solution, but it was incomplete/buggy */}
                {store.isSmallDevice && <div style={{ display: "flex", padding: "0 10px 10px" }}>
                    <Input.Search
                        style={{ flex: 1 }}
                        {...search_props}
                    />
                </div>}
            </Layout.Header>
            <Layout.Content style={{ padding: "12px 24px" }}>
                {props.children}
            </Layout.Content>
        </Layout>
    </Layout>
});

const btheme = {
    // navColor: "rgb(20,20,20)", // Flat, dark gray
    navColor: "rgb(20,22,25)", // Dark Slate
    // navColor: "rgb(20,25,30)", // Slate
}
// const light_theme = {
//     navColor: "rgb(210,215,220)"
// }

const THEME: ThemeConfig = {
    algorithm: theme.darkAlgorithm,
    token: {
        // colorPrimary: 'rgba(209, 182, 46, 1)', // Darker/goldenrod
        colorPrimary: 'rgba(238, 207, 48, 1)',
        // borderRadius: 0,
    },
    components: {
        Layout: {
            // siderBg: "#333",
            lightSiderBg: btheme.navColor,
            headerBg: btheme.navColor,
        },
        Menu: {
            itemBg: btheme.navColor,
            // darkSubMenuItemBg: "#222",
            // darkItemHoverBg: "red",
            // darkItemSelectedBg: "red",
            activeBarBorderWidth: 0,
        },
    },
};

export const AppLayout = observer((props: { children?: React.ReactNode }) => {
    return <>
        <ConfigProvider
            theme={THEME}
        >
            <App>
                <InnerLayout {...props} />
            </App>
        </ConfigProvider>
    </>
})
