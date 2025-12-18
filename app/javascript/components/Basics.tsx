import classNames from "classnames";
import { ComponentProps, HTMLProps } from "react";

const extractClassNames = (props: any, booleans: string[]) => {
    const compiled_props = { ...props };
    const class_names: any[] = [];
    for (const bool of booleans) {
        if (compiled_props[bool]) {
            class_names.push(bool);
            delete compiled_props[bool];
        }
    }
    compiled_props["className"] = classNames(compiled_props["className"], ...class_names);
    return compiled_props;
};

export const Content = (props: { "with-background"?: boolean; "unpadded"?: boolean; "unpadded-v"?: boolean } & HTMLProps<HTMLDivElement>) => {
    const pass = extractClassNames(props, [
        "with-background", "unpadded", "unpadded-v"
    ]);
    return <div
        {...pass}
        className={classNames("content-box", pass.className)}
    />
}

export const Box = (props: ComponentProps<typeof Content>) => {
    return <Content with-background {...props} />
}

Box.Unpadded = (props: HTMLProps<HTMLDivElement>) => {
    return <Box unpadded {...props} />
}

Box.UnpaddedV = (props: HTMLProps<HTMLDivElement>) => {
    return <Box unpadded-v {...props} />
}
