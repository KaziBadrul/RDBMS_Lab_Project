import LoginForm from "@/components/LoginForm";

export const metadata = {
    title: "Sign In — TripWise",
};

export default function LoginPage() {
    return (
        <main className="flex min-h-screen items-center justify-center p-4">
            <div className="w-full max-w-md">
                {/* Header */}
                <h1 className="text-4xl font-bold text-darkRed mb-8 text-center">
                    TripWise
                </h1>

                <LoginForm />
            </div>
        </main>
    );
}
