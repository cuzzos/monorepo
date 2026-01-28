export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-24 bg-zinc-950">
      <h1 className="text-5xl font-bold text-white tracking-tight">
        Welcome to <span className="text-emerald-400">Thiccc</span>
      </h1>
      <p className="mt-4 text-xl text-zinc-400">
        Workout tracking app
      </p>
      <div className="mt-8 flex gap-4">
        <a
          href="/workouts"
          className="rounded-lg bg-emerald-500 px-6 py-3 text-lg font-semibold text-white hover:bg-emerald-600 transition-colors"
        >
          Get Started
        </a>
        <a
          href="/about"
          className="rounded-lg border border-zinc-700 px-6 py-3 text-lg font-semibold text-zinc-300 hover:bg-zinc-800 transition-colors"
        >
          Learn More
        </a>
      </div>
    </main>
  );
}
