
export const CHARSET = {
    ALPHANUMERIC: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",
    NUMERIC: "0123456789",
    HEXADECIMAL: "0123456789ABCDEF",
} as const;

export function generateToken(length: number = 8, charset: string = CHARSET.ALPHANUMERIC): string {
    const chars = charset;
    let token = "";
    for (let i = 0; i < length; i++) {
        token += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return token;
}
