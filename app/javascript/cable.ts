
import { createConsumer } from "@rails/actioncable";
import { AppStore } from "./data/app_store";
import { runInAction } from "mobx";

type Message<T extends any> = { id: string } & T;

const CABLE = createConsumer();
CABLE.subscriptions.create({ channel: "ClientChannel" }, {
    assign_uid(data: Message<{ uid: string }>) {
        AppStore.instance.client_uid = data.uid;
    },
    scanner_subscribed(data: Message<{ scanner_id: string }>) {
        AppStore.instance.paired_scanner_id = data.scanner_id;
    },
    received(data) {
        runInAction(() => {
            if (this[data.type]) {
                this[data.type](data);
            } else {
                console.error(`Unknown message type: ${data.type}`);
            }
        })
    }
});
