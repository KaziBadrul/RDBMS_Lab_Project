import { prisma } from "@/lib/prisma";

export async function GET() {
    try {
        const routes = await prisma.route.findMany({
            orderBy: { startLocation: "asc" },
        });
        return Response.json(routes);
    } catch (error) {
        return new Response("Failed to fetch routes", { status: 500 });
    }
}
