import React, { useMemo } from "react";
import moment, { Moment } from "moment";
import { Text, View } from "@instructure/ui";

export const FormatTime: React.FC<{ time: Moment | string, format?: string }> = ({ time, format }) => {
    if (!time) return '-';
    const momentTime = useMemo(() => typeof time == 'string' ? moment(time) : time, [time]);
    return momentTime.format(format || 'LLL') as any;
}

export const FormatTimeSpent: React.FC<{ seconds: number }> = ({ seconds: total_seconds }) => {
    const hours = Math.floor(total_seconds / 3600);
    const minutes = Math.floor((total_seconds % 3600) / 60);
    const seconds = Math.floor(total_seconds % 60);

    const time_bits = [minutes, seconds];
    if (hours > 0) time_bits.unshift(hours);

    const time_str = time_bits.map((n, i) => n.toString().padStart(i == 0 ? 1 : 2, "0")).join(":");

    return <>
        {time_str}
    </>
}

export const FormatTimeRange: React.FC<{ start: Moment | string, end: Moment | string, format?: string }> = ({ start, end, format }) => {
    if (!start && !end) return <>All</>;

    if (!start) {
        return <>
            Before <FormatTime time={end} format={format} />
        </>
    }

    if (!end) {
        return <>
            After <FormatTime time={start} format={format} />
        </>
    }
    return <>
        <FormatTime time={start} format={format} /> to <FormatTime time={end} format={format} />
    </>
}
