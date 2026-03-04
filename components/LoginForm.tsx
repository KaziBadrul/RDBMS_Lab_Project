"use client";

import { useState } from "react";
import { useActionState } from "react";
import { handleLogin } from "@/app/login/actions";

export default function LoginForm() {
    const [state, formAction, isPending] = useActionState(handleLogin, null);
    const [showPassword, setShowPassword] = useState(false);

    return (
        <form action={formAction} className="w-full max-w-md space-y-6">
            {/* Card container */}
            <div className="bg-white rounded-2xl shadow-lg p-8 border-t-4 border-red">
                <h2 className="text-2xl font-bold text-navy mb-1">Welcome Back</h2>
                <p className="text-sm text-gray-500 mb-6">
                    Sign in to access TripWise
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

                {/* Password field */}
                <label htmlFor="password" className="block text-sm font-medium text-navy mb-1 mt-4">
                    Password
                </label>
                <div className="relative">
                    <input
                        id="password"
                        name="password"
                        type={showPassword ? "text" : "password"}
                        required
                        placeholder="Enter your password"
                        className="w-full rounded-lg border border-gray-300 px-4 py-2.5 pr-12 text-navy placeholder-gray-400 focus:border-blue focus:ring-2 focus:ring-blue/30 outline-none transition"
                    />
                    <button
                        type="button"
                        onClick={() => setShowPassword(!showPassword)}
                        className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-navy transition text-sm select-none"
                        tabIndex={-1}
                    >
                        {showPassword ? "Hide" : "Show"}
                    </button>
                </div>

                {/* Stay logged in checkbox */}
                <label htmlFor="rememberMe" className="mt-4 flex items-center gap-2 cursor-pointer select-none">
                    <input
                        id="rememberMe"
                        name="rememberMe"
                        type="checkbox"
                        className="h-4 w-4 rounded border-gray-300 text-darkRed focus:ring-darkRed accent-darkRed"
                    />
                    <span className="text-sm text-navy">Stay logged in</span>
                </label>

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
