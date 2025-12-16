
import classNames from "classnames";
import "material-symbols";
import { MaterialSymbol } from "material-symbols";
import { HTMLProps } from "react";

export const Icon = ({ icon, variant = "outlined", className, ...rest }: {
    icon: MaterialSymbol,
    variant?: "outlined" | "rounded" | "sharp",
} & HTMLProps<HTMLSpanElement>) => {
    return <span className={classNames(`material-symbols-${variant}`, "mdi", className)} {...rest}>
        {icon}
    </span>
}
