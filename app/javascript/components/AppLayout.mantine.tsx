import { observer } from "mobx-react";
import { useContext } from "react";
import { Link, useLocation } from "react-router-dom";

import { AppShell, Box, Burger, createTheme, Group, MantineProvider, Menu, NavLink, ScrollArea, Tooltip } from "@mantine/core";
import type { ItemType, MenuItemType } from "antd/es/menu/interface";

import { AppStore } from "@/data/app_store";
import { MENU_ITEMS } from "./MenuItems";

import '@mantine/core/styles.css';
import "./screen.mantine.less";

function MenuLinkItem({ link }: { link: ItemType<MenuItemType> }) {
    if (link.children) {
        return <Menu.Sub openDelay={120} closeDelay={150}>
            <Menu.Sub.Target>
                <Menu.Sub.Item leftSection={link.icon}>{link.label}</Menu.Sub.Item>
            </Menu.Sub.Target>

            <Menu.Sub.Dropdown>
                {link.children.map(child => <MenuLinkItem key={child.key} link={child} />)}
            </Menu.Sub.Dropdown>
        </Menu.Sub>
    } else {
        return <Menu.Item
            component={Link}
            leftSection={link.icon}
            to={link.key}

        >{link.label}</Menu.Item>
    }
}

function CompactNavLinks(props: { links: ItemType<MenuItemType>[] }) {
    const location = useLocation();

    const link_components = props.links.map(link => {
        const is_current = location.pathname.startsWith(link.key as string);

        const nav_props = {
            href: "#",
        }

        if (!link.children) {
            Object.assign(nav_props, {
                component: Link,
                href: link.key,
                to: link.key,
            });
        }

        let component = <NavLink
            active={is_current}
            variant="subtle"
            label={<span style={{ fontSize: "1.3rem" }}>{link.icon}</span>}
            {...nav_props}
        />

        if (link.children) {
            component = <Menu key={link.key} position="right-start" trigger="hover">
                <Menu.Target>
                    {component}
                </Menu.Target>
                <Menu.Dropdown>
                    {link.children.map(child => <MenuLinkItem key={child.key} link={child} />)}
                </Menu.Dropdown>
            </Menu>
        } else {
            component = <Tooltip key={link.key} label={link.label} position="right" transitionProps={{ duration: 0 }}>
                {component}
            </Tooltip>
        }

        return component;
    });
    return <>{link_components}</>;
}

function NavLinks(props: { links: ItemType<MenuItemType>[] }) {
    const location = useLocation();

    const link_components = props.links.map(link => {
        const is_current = location.pathname.startsWith(link.key as string);

        return <NavLink
            key={link.key}
            href={link.key}
            to={link.key}
            active={is_current}
            variant="subtle"
            label={link.label}
            leftSection={link.icon}
            defaultOpened={is_current}
            component={Link}
            childrenOffset="sm"
        >
            {link.children && <NavLinks links={link.children} />}
        </NavLink>
    });
    return <>{link_components}</>;
}

const mtheme = createTheme({
    primaryColor: "yellow",
})

export const AppLayout = observer((props: { children?: React.ReactNode }) => {
    const store = useContext(AppStore.Context);

    const collapsed = store.sidebarCollapsed;
    const toggle = () => { store.sidebarCollapsed = !store.sidebarCollapsed; }

    return <>
        <MantineProvider theme={mtheme} defaultColorScheme="dark">
            <AppShell
                layout="alt"
                header={{ height: 64 }}
                footer={{ height: 60 }}
                navbar={{ width: collapsed ? 64 : 220, breakpoint: 'sm', collapsed: { mobile: collapsed, desktop: false } }}
                padding="md"
            >
                <AppShell.Header>
                    <Group h="100%" px="md">
                        <Burger opened={!collapsed} onClick={toggle} size="sm" />
                        Header
                    </Group>
                </AppShell.Header>

                <AppShell.Navbar className={(collapsed && !store.isSmallDevice) ? "navbar-icons-only" : ""}>
                    <Group p="md" className="logo-wrapper">
                        <Burger opened={!collapsed} onClick={toggle} hiddenFrom="sm" size="sm" />
                        <div className="logo-sidebar">
                            <div className="logo-icon" />
                            <div className="logo-logotype">
                                <div title="Now for more than just batteries!" className="logo-title">BattMan</div>
                                <div className="logo-subtitle">Home Inventory Management</div>
                            </div>
                        </div>
                    </Group>

                    <Box style={{ scrollbarWidth: "none", width: "100%", whiteSpace: "nowrap" }}>
                        <NavLinks links={MENU_ITEMS} />
                    </Box>
                </AppShell.Navbar>

                <AppShell.Main>
                    {props.children}
                </AppShell.Main>
                {/* <AppShell.Footer p="md">Footer</AppShell.Footer> */}
            </AppShell>
        </MantineProvider>
    </>
})
