import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Thiccc - Workout Tracker',
  description: 'Track your workouts, analyze your progress',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
