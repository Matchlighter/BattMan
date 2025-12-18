
export interface Thing {
    id?: string;
    icon?: string;
    serial_number?: string;
    implements?: Thing[];

    [key: string]: any;
}
