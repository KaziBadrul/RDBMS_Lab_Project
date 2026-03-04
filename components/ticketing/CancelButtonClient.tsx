"use client";

import { useState } from "react";
import { formatDistanceToNow, differenceInHours } from "date-fns";

export default function CancelButtonClient({
    ticketId,
    departureTime,
    price
}: {
    ticketId: number;
    departureTime: string;
    price: number;
}) {
    const [isConfirming, setIsConfirming] = useState(false);
    const [loading, setLoading] = useState(false);
    const [reason, setReason] = useState("");

    const hoursLeft = differenceInHours(new Date(departureTime), new Date());

    let refundPercent = 50;
    if (hoursLeft > 24) refundPercent = 100;
    else if (hoursLeft >= 12) refundPercent = 75;

    const refundAmount = (price * refundPercent) / 100;

    async function handleCancel() {
        setLoading(true);
        try {
            const res = await fetch(`/api/tickets/${ticketId}/cancel`, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ reason }),
            });

            if (!res.ok) {
                const data = await res.json();
                throw new Error(data.error || "Failed to cancel");
            }

            window.location.reload();
        } catch (err: any) {
            alert(err.message);
            setLoading(false);
        }
    }

    if (isConfirming) {
        return (
            <div className="bg-red-50 p-4 rounded-lg border border-red-100 flex flex-col gap-3 max-w-sm ml-auto">
                <p className="text-xs text-red-800 font-medium">
                    Estimated Refund: <span className="text-sm font-bold">৳{refundAmount}</span> ({refundPercent}%)
                </p>
                <input
                    type="text"
                    placeholder="Reason (optional)"
                    className="text-xs p-2 border border-red-200 rounded focus:outline-none focus:ring-1 focus:ring-red-400"
                    value={reason}
                    onChange={(e) => setReason(e.target.value)}
                />
                <div className="flex gap-2 justify-end">
                    <button
                        disabled={loading}
                        onClick={() => setIsConfirming(false)}
                        className="text-xs font-bold text-gray-500 hover:text-gray-700 px-3 py-1.5"
                    >
                        Go Back
                    </button>
                    <button
                        disabled={loading}
                        onClick={handleCancel}
                        className="text-xs font-bold bg-darkRed text-white px-3 py-1.5 rounded hover:bg-red-700 disabled:opacity-50 transition-colors"
                    >
                        {loading ? "Processing..." : "Confirm Cancellation"}
                    </button>
                </div>
            </div>
        );
    }

    return (
        <button
            onClick={() => setIsConfirming(true)}
            className="text-sm font-bold text-darkRed border border-darkRed/20 px-4 py-2 rounded-lg hover:bg-darkRed hover:text-white transition-all"
        >
            Cancel Ticket
        </button>
    );
}
