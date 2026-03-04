import { prisma } from "./lib/prisma";

async function check() {
    console.log("Prisma keys:", Object.keys(prisma).filter(k => !k.startsWith("_")));
    if (prisma.priceChangeLog) {
        console.log("priceChangeLog found!");
    } else {
        console.log("priceChangeLog NOT found!");
        // Check for potential case differences
        const possible = Object.keys(prisma).filter(k => k.toLowerCase().includes("price"));
        console.log("Potential matches:", possible);
    }
}

check().catch(console.error);
