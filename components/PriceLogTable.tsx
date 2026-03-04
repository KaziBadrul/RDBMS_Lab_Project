import { format } from "date-fns";

interface PriceLog {
    logId: number;
    tripId: number;
    oldPrice: any; // Using any for Decimal compatibility
    newPrice: any;
    reason: string;
    changedAt: Date;
    trip: {
        route: {
            startLocation: string;
            endLocation: string;
        };
        vehicle: {
            licensePlate: string;
        };
    };
}

export default function PriceLogTable({ logs }: { logs: PriceLog[] }) {
    return (
        <div className="overflow-x-auto bg-white rounded-lg shadow border border-gray-200">
            <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                    <tr>
                        <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Date</th>
                        <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Route</th>
                        <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Vehicle</th>
                        <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Price Change</th>
                        <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Reason</th>
                    </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                    {logs.length === 0 ? (
                        <tr>
                            <td colSpan={5} className="px-6 py-10 text-center text-gray-500 italic">No pricing changes logged yet.</td>
                        </tr>
                    ) : (
                        logs.map((log) => (
                            <tr key={log.logId} className="hover:bg-gray-50 transition-colors">
                                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-600">
                                    {format(new Date(log.changedAt), "MMM d, yyyy HH:mm")}
                                </td>
                                <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-navy">
                                    {log.trip.route.startLocation} → {log.trip.route.endLocation}
                                </td>
                                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-600">
                                    {log.trip.vehicle.licensePlate}
                                </td>
                                <td className="px-6 py-4 whitespace-nowrap text-sm">
                                    <span className="text-gray-400 line-through mr-2">৳{Number(log.oldPrice)}</span>
                                    <span className="text-darkRed font-bold">৳{Number(log.newPrice)}</span>
                                </td>
                                <td className="px-6 py-4 text-sm text-gray-700">
                                    <span className={`px-2 py-1 rounded-full text-xs font-medium ${log.reason.includes("surge") ? "bg-red-100 text-red-700" : "bg-green-100 text-green-700"
                                        }`}>
                                        {log.reason}
                                    </span>
                                </td>
                            </tr>
                        ))
                    )}
                </tbody>
            </table>
        </div>
    );
}
