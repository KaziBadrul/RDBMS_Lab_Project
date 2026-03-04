import { cookies } from "next/headers";

export interface SessionUser {
    userId: number;
    username: string;
    role: string;
}

const COOKIE_NAME = "session_user";

export async function login(user: SessionUser, rememberMe = false) {
    const cookieStore = await cookies();
    cookieStore.set(COOKIE_NAME, JSON.stringify(user), {
        httpOnly: true,
        secure: process.env.NODE_ENV === "production",
        sameSite: "lax",
        path: "/",
        // 30 days if "Stay logged in" is checked, otherwise session-only
        ...(rememberMe ? { maxAge: 60 * 60 * 24 * 30 } : {}),
    });
}

export async function logout() {
    const cookieStore = await cookies();
    cookieStore.delete(COOKIE_NAME);
}

export async function getCurrentUser(): Promise<SessionUser | null> {
    const cookieStore = await cookies();
    const raw = cookieStore.get(COOKIE_NAME)?.value;
    if (!raw) return null;
    try {
        return JSON.parse(raw) as SessionUser;
    } catch {
        return null;
    }
}
