import { useContext, useEffect, useState } from "react";

import { AppStore } from "@/data/app_store";
import { QRCode } from "antd";

export const QR = ({ ...rest }: React.ComponentProps<typeof QRCode>) => {
    return <QRCode
        color="black"
        bgColor="white"
        {...rest}
    />
}

export const ClientActionQR = ({ action, ...rest }: { action: string } & Omit<React.ComponentProps<typeof QRCode>, "value">) => {
    const store = useContext(AppStore.Context);
    return <QR value={`BATTMAN:CLIENT:${store.client_conn_uid}:${action}`}
        {...rest}
    />
}

export const ClientCallbackQR = ({ callback, ...rest }: { callback: (scanner: any) => void } & Omit<React.ComponentProps<typeof QRCode>, "value">) => {
    const store = useContext(AppStore.Context);
    const [codeData, setCodeData] = useState<string | null>(null);

    useEffect(() => {
        const { token, unregister } = store.client_codes_store.registerClientCode(callback);
        setCodeData(token);
        return unregister;
    }, [callback, store.client_conn_uid]);

    if (!codeData) return null;

    return <ClientActionQR action={codeData} {...rest} />
}
