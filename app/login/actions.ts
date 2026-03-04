"use server";

import { prisma } from "@/lib/prisma";
import { verifyPassword } from "@/lib/password";
import { login } from "@/lib/auth";
import { redirect } from "next/navigation";

export async function handleLogin(
    _prevState: { error: string } | null,
    formData: FormData,
) {
    const username = (formData.get("username") as string)?.trim();
    const password = (formData.get("password") as string) ?? "";
    const rememberMe = formData.get("rememberMe") === "on";

    if (!username || !password) {
        return { error: "Please enter both username and password." };
    }

    const user = await prisma.userRole.findUnique({
        where: { username },
    });

    if (!user || !(await verifyPassword(password, user.passwordHash))) {
        return { error: "Invalid username or password." };
    }

    await login(
        {
            userId: user.userId,
            username: user.username,
            role: user.role,
        },
        rememberMe,
    );

    redirect("/");
}
