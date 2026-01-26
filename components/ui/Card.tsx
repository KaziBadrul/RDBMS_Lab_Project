export function Card({
  title,
  description,
  action,
}: {
  title: string;
  description: string;
  action: string;
}) {
  return (
    <section className="bg-white rounded-2xl shadow-lg p-6 border-t-4 border-red transition hover:-translate-y-1">
      <h2 className="text-xl font-semibold text-navy mb-2">{title}</h2>
      <p className="text-sm text-gray-600 mb-4">{description}</p>
      <button className="mt-auto inline-flex items-center justify-center px-4 py-2 rounded-full bg-navy text-white font-medium hover:bg-blue transition">
        {action}
      </button>
    </section>
  );
}
