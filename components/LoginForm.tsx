"use client";

import { useActionState } from "react";
import { handleLogin } from "@/app/login/actions";

export default function LoginForm() {
    const [state, formAction, isPending] = useActionState(handleLogin, null);

    return (
        <form action={formAction} className="w-full max-w-md space-y-6">
            {/* Card container */}
            <div className="bg-white rounded-2xl shadow-lg p-8 border-t-4 border-red">
                <h2 className="text-2xl font-bold text-navy mb-1">Welcome Back</h2>
                <p className="text-sm text-gray-500 mb-6">
                    Sign in to access the City Transportation System
                </p>

                {/* Error message */}
                {state?.error && (
                    <div className="mb-4 rounded-lg bg-red-50 border border-red-200 px-4 py-3 text-sm text-red-700">
                        {state.error}
                    </div>
                )}

                {/* Username field */}
                <label htmlFor="username" className="block text-sm font-medium text-navy mb-1">
                    Username
                </label>
                <input
                    id="username"
                    name="username"
                    type="text"
                    required
                    autoFocus
                    placeholder="Enter your username"
                    className="w-full rounded-lg border border-gray-300 px-4 py-2.5 text-navy placeholder-gray-400 focus:border-blue focus:ring-2 focus:ring-blue/30 outline-none transition"
                />

                {/* Submit button */}
                <button
                    type="submit"
                    disabled={isPending}
                    className="mt-6 w-full rounded-full bg-darkRed px-4 py-2.5 font-semibold text-white hover:bg-red transition disabled:opacity-60 disabled:cursor-not-allowed"
                >
                    {isPending ? "Signing in…" : "Sign In"}
                </button>
            </div>
        </form>
    );
}
