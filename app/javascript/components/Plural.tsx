import React from "react";
import lib_pluralize from "pluralize";

export const pluralize: typeof lib_pluralize = (phrase: string, ...rest) => {
    const split = phrase.split(' ');
    split[split.length - 1] = lib_pluralize(split[split.length - 1], ...rest);
    return split.join(' ');
};

export const Pluralize = ({ phrase, count }: { phrase: string, count: number }) => {
    return <>{pluralize(phrase, count)}</>;
}
