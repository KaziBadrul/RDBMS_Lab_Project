"use server";

import { prisma } from "@/lib/prisma";
import { login } from "@/lib/auth";
import { redirect } from "next/navigation";

export async function handleLogin(
    _prevState: { error: string } | null,
    formData: FormData,
) {
    const username = (formData.get("username") as string)?.trim();

    if (!username) {
        return { error: "Please enter a username." };
    }

    const user = await prisma.userRole.findUnique({
        where: { username },
    });

    if (!user) {
        return { error: "User not found. Please check your username." };
    }

    await login({
        userId: user.userId,
        username: user.username,
        role: user.role,
    });

    redirect("/");
}
