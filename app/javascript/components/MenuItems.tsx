
import type { ItemType, MenuItemType } from "antd/es/menu/interface";

import { Icon } from "./Icon";
import { dft } from "@matchlighter/common_library/lib/data/traversal";

export const MENU_ITEMS: ItemType<MenuItemType>[] = [
    {
        key: '/things/xyz',
        icon: <Icon icon="location_on" />,
        label: '[TEMP] Thing',
    },
    {
        key: '/locations',
        icon: <Icon icon="location_on" />,
        label: 'Locations',
    },
    {
        key: '/items',
        icon: <Icon icon="art_track" />,
        label: 'Items',
        children: [
            {
                key: '/items/devices',
                icon: <Icon icon="devices" />,
                label: 'Devices',
            },
            {
                key: '/items/appliances',
                icon: <Icon icon="microwave" />,
                label: 'Appliances',
            },
            {
                key: '/products',
                icon: <Icon icon="orders" />,
                label: 'Products',
            },
        ]
    },
    {
        key: '/groceries',
        icon: <Icon icon="grocery" />,
        label: 'Groceries',
        children: [
            {
                key: '/groceries/list',
                icon: <Icon icon="shopping_cart" />,
                label: 'Shopping List',
            },
            {
                key: '/groceries/stock',
                icon: <Icon icon="shelves" />,
                label: 'Stock',
            },
            {
                key: '/groceries/products',
                icon: <Icon icon="grocery" />,
                label: 'Products',
            },
        ]
    },
    {
        key: '/scan-logs',
        icon: <Icon icon="barcode_reader" />,
        label: 'Scanners',
    },
    {
        key: '/templates',
        icon: <Icon icon="contextual_token" />,
        label: 'Templates',
    },
    {
        key: '/settings',
        icon: <Icon icon="settings" />,
        label: 'Settings',
    },
];
