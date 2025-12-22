import { CHARSET, generateToken } from "@/util";

export const getClientUid = (): string => {
    let uid = window.localStorage.getItem("battman_client_uid");
    if (!uid) {
        uid = generateToken(8, CHARSET.HEXADECIMAL);
        window.localStorage.setItem("battman_client_uid", uid);
    }
    return uid;
};
