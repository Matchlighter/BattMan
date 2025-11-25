
import { createConsumer } from "@rails/actioncable";

const CABLE = createConsumer();

CABLE.subscriptions.create({ channel: "ScanLogChannel", _html: true }, {
    received(data) {
        $(data._html).toast({ displayTime: 10000 });
    }
});
