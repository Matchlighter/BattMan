
import { createConsumer } from "@rails/actioncable";

export type Message<T extends any> = { id: string } & T;

export const CABLE = createConsumer();
